#!/usr/bin/perl
# hybrid http://www.linux.com/community/blogs/Perl-Creating-a-compiled-daemon.html
# and http://www.perlmonks.org/index.pl?node_id=478839
# and /home/dave/src/netmorpher/trunk/httpd/content/backend/nodes/domains/de/boerse-frankfurt/driver.pl
# $Id: eventd.pl 125 2010-11-13 19:47:54Z dave $

use strict;
use warnings;
use POSIX qw( :sys_wait_h );
use Log::Dispatch;
use Log::Dispatch::File;
use Date::Format;
use File::Spec;
use JSON::XS;
use Time::Local;
use ENV;
use Utils;
use IO::CaptureOutput qw( capture_exec_combined );

my ( $ME ) = $0 =~ m|.*/(.*)|;
my %commands = (
   seed    => \&seed,
   start   => \&checkPreconditions,
   stop    => \&stop,
   restart => \&restart,
);

my $command = scalar( @ARGV ) && exists( $commands{$ARGV[0]} ) ? $commands{$ARGV[0]} : \&usage;
my $log; # global
$command->();
exit( 0 );


sub checkPreconditions {
   my $logdir = $ENV{EVENTD_LOG_DIR};
   $logdir = Utils::pwd() . $logdir if ( $logdir !~ m|^/| );

   chdir( '/' ) or dienice( "can't chdir to /: $!" );

   # TODO: check pid; write pid

   # setup a logging agent
   $log = new Log::Dispatch(
      callbacks => sub {
         my %h = @_;
         return Date::Format::time2str( '%b %e %T', time() ) . " $ME\[$$\]: " . $h{message} . "\n";
      }
   );
   $log->add( Log::Dispatch::File->new(
      name      => $ME,
      min_level => 'warning',
      mode      => 'append',
      bindmode  => ':utf8',
      filename  => File::Spec->catfile( $logdir, $ENV{EVENTD_LOG_FILE} ),
   ) );

   start();
}


sub start {
   $log->warning( "started $ME" );

   # setup signal handlers
   my $keep_going = 1;
   $SIG{HUP}  = sub { $log->warning( 'caught SIGHUP: exiting gracefully' ); $keep_going = 0; };
   $SIG{INT}  = sub { $log->warning( 'caught SIGINT: exiting gracefully' ); $keep_going = 0; };
   $SIG{QUIT} = sub { $log->warning( 'caught SIGQUIT: exiting gracefully' ); $keep_going = 0; };
   #$SIG{TERM} = sub { $log->warning( 'caught SIGTERM: exiting gracefully' ); $keep_going = 0; };
   $SIG{CHLD} = sub { $log->critical( "got SIGCHILD with $?" ) if ( $? && $? != -1 ); }; # TODO: give meaningful feedback

   my %kids; # map of spawned kid pids
   my $period = $ENV{EVENTD_PERIOD};
   my $sql =<<EOSQL;
SELECT id, UNIX_TIMESTAMP( at ), command
FROM events
WHERE state = 'INSERTED'
AND TIMESTAMPDIFF( SECOND, ?, at ) >= 0
AND TIMESTAMPDIFF( SECOND, at, ? ) >= 0
ORDER BY at
EOSQL
   my $dbh = Utils::getDBH();
   my $sth = $dbh->prepare( $sql ) or dienice( $dbh->errstr );

   while ( $keep_going ) { # main loop
      my $past = substr( `date -u -d 'yesterday' +"%Y-%m-%d %H:%M:%S"`, 0, -1 );
      my $future = substr( `date -u -d 'now + $period seconds' +"%Y-%m-%d %H:%M:%S"`, 0, -1 );
      my $logline = "checked $past to $future";

      $sth->execute( $past, $future ) or dienice( $dbh->errstr );

      while ( my ( $id, $at, $command ) = $sth->fetchrow_array() ) {
         my $kidpid = spawn( $id, $at, $command );
         $kids{$kidpid} = 1;
      }

      map { delete( $kids{$_} ) if ( waitpid( $_, WNOHANG ) > 0 ); } keys( %kids );

      $logline .= "; kids = " . join( ', ', sort( keys( %kids ) ) ) if ( scalar( keys( %kids ) ) );

      $log->warning( $logline );

      sleep( $period );
   }

   $sth->finish() or dienice( $dbh->errstr );
   $dbh->disconnect();

   $log->warning( 'waiting for ' . scalar( keys( %kids ) ) . ' kids to exit' );

   map { waitpid( $_, 0 ); } keys( %kids );

   $log->warning( "stopped $ME" );
}


sub stop {
   # TODO: `kill -s HUP pid`;
}


sub restart {
   stop();
   start();
}


sub dienice($) { # write die messages to the log before die'ing
  my ( $package, $filename, $line ) = caller;
  $log->critical( "$_[0] at line $line in $filename" );
  die $_[0];
}


sub spawn {
   my ( $id, $at, $json ) = @_;

   FORK: {
      if ( my $kidpid = fork() ) {
         # parent here; child process pid is available in $kidpid
         return $kidpid; # don't block; we reap in/after the main loop
      } elsif ( defined( $kidpid ) ) { # $kidpid is zero here if defined
         # child here; parent process pid is available with getppid
         close( STDIN ) or dienice( "couldn't close STDIN: $!" );
         close( STDOUT ) or dienice( "couldn't close STDOUT: $!" );
         close( STDERR ) or dienice( "couldn't close STDERR: $!" );
      } elsif ( $! =~ /No more process/ ) {
         # EAGAIN, supposedly recoverable fork error
        sleep 5;
        redo FORK;
      } else {
         # weird fork error
         dienice( "can't fork: $!\n" );
      }
   }

   # kid here since parent either returned in FORK or we all died
   my $perl = JSON::XS->new->utf8->decode( $json ) or dienice( 'expected JSON object or array at beginning of string' );
   $json = JSON::XS->new->utf8->encode( $perl ) or dienice( "couldn't encode perl to JSON" );
   chdir( $perl->{$ENV{CMD_KEY_WD}} ) or dienice( "can't chdir to $perl->{$ENV{CMD_KEY_WD}}: $!" );
   $log->warning( "chdir'ed to $perl->{$ENV{CMD_KEY_WD}}" );

   my $dbh = Utils::getDBH();
   my $now = gmtime();
   my $sql = "UPDATE events SET state='SCHEDULED', log=CONCAT( log, '[$now] scheduled by pid $$\n' ) WHERE id=$id";
   $dbh->do( $sql ) or dienice( $dbh->errstr );
   $dbh->disconnect(); # disconnect since sleeping could take a while

   # sleep 'til $at
   my $rollback = sub {
      my $sig = shift;
      $dbh = Utils::getDBH();
      $now = gmtime();
      $sql = "UPDATE events SET state='INSERTED', log=CONCAT( log, '[$now] reverted to INSERTED on SIG$sig\n' ) WHERE id=$id";
      $dbh->do( $sql ) or dienice( $dbh->errstr );
      $log->warning( "caught SIG$sig: exiting gracefully: updated $id to INSERTED for rescheduling" );
      $dbh->disconnect(); # disconnect since exe could take a while
      exit( 0 );
   };
   local $SIG{HUP}  = sub { &$rollback( 'HUP' ); };
   local $SIG{INT}  = sub { &$rollback( 'INT' ); };
   local $SIG{QUIT} = sub { &$rollback( 'QUIT' ); };
   #local $SIG{TERM} = sub { &$rollback( 'TERM' ); };

   $now = time(); # not gmtime
   my $nap = $at - timelocal( gmtime( $now ) );
   $log->warning( "updated $id to SCHEDULED; sleeping for ${nap}s 'til localtime " . Date::Format::time2str( '%b %e %T', $now + $nap ) );
   sleep( $nap ) if ( $nap > 0 ); # could be < 0 on recovery from SIGINT, etc

   $dbh = Utils::getDBH();
   $now = gmtime();
   $sql = "UPDATE events SET state='RUNNING', log=CONCAT( log, '[$now] running with ppid $$\n' ) WHERE id=$id";
   $dbh->do( $sql ) or dienice( $dbh->errstr );
   $dbh->disconnect(); # disconnect since exe could take a while

   $log->warning( "updated $id to RUNNING; about to $perl->{exe} '$json'" );
   my ( $output, $success, $result ) = capture_exec_combined( $perl->{exe}, "$json" );
   $result >>= 8;

   $dbh = Utils::getDBH();
   $now = gmtime();
   my $appendage = "[$now] backticks exited with $result (\$success == $success)\n";
   my $outcome = 'SUCCEEDED';
   if ( !$success ) {
      $log->critical( 'output = ' . $output );
      $outcome = 'FAILED';
   }
   $appendage .= "$output\n" if ( !$success || exists( $perl->{$ENV{CMD_KEY_VERBOSE}} ) );
   $appendage =~ s|'|''|g; # ' syntax highlighting
   $sql = "UPDATE events SET state='$outcome', log=CONCAT( log, '$appendage' ) WHERE id=$id";
   $dbh->do( $sql ) or dienice( $dbh->errstr );
   $dbh->disconnect();

   if ( exists( $perl->{$ENV{CMD_KEY_MAILTO}} ) || $outcome eq 'FAILED' ) {
      my $recipient = exists( $perl->{$ENV{CMD_KEY_MAILTO}} ) ? $perl->{$ENV{CMD_KEY_MAILTO}} : $ENV{USER};
      my $subject = "$perl->{$ENV{CMD_KEY_EXE}} $outcome $ENV{DB_ULYZ_HOST}:$ENV{DB_ULYZ_EBAY}.events.id=$id";
      my $success = !mail( $recipient, $subject, $output, $0 );
      my $feedback = $success
                   ? "emailed $perl->{$ENV{CMD_KEY_MAILTO}}"
                   : "failed to email $perl->{$ENV{CMD_KEY_MAILTO}}\n$output";
      $log->warning( $feedback );
   }
   $log->warning( "updated $id to $outcome" );

   exit( 0 );
}


sub seed {
   $| = 1;
   print( "You are about to truncate $ENV{DB_ULYZ_HOST}:$ENV{DB_ULYZ_EBAY}.events.  Enter 'notprod' to continue: " );
   my $confirm = <STDIN>;
   return if ( $confirm !~ m|notprod| );

   my $dbh = Utils::getDBH();

   while ( my $sql = <DATA> ) {
      #print $sql;
      $dbh->do( $sql ) or die $dbh->errstr;
   }

   $dbh->disconnect();
}


sub mail {
   my ( $recipient, $subject, $body, $from, $to ) = @_;
   my $From = defined( $from ) ? "From: $from" : '';
   my $To = defined( $to ) ? "\nTo: $to" : '';
   `cat <<'EOMAIL' | /usr/sbin/sendmail $recipient;
Subject: $subject
$From$To

$body
EOMAIL`;
   return $?;
}


sub usage {
   my $commands = join( '|', sort( keys( %commands ) ) );
   my $password = $ENV{DB_ULYZ_PASSWORD} eq 'xxx' ? 'xxx' : 'set by shell environment, not ENV.pm';
   exit !print <<EOS;
usage: $0 ($commands)

configuration from ENV.pm:
   EVENTD_PERIOD   = $ENV{EVENTD_PERIOD}
   EVENTD_LOG_DIR  = $ENV{EVENTD_LOG_DIR}
   EVENTD_LOG_FILE = $ENV{EVENTD_LOG_FILE}

   DB_ULYZ_EBAY = $ENV{DB_ULYZ_EBAY}
   DB_ULYZ_HOST = $ENV{DB_ULYZ_HOST}
   DB_ULYZ_PORT = $ENV{DB_ULYZ_PORT}
   DB_ULYZ_USER = $ENV{DB_ULYZ_USER}
   DB_ULYZ_PASSWORD = $password
EOS
}


__DATA__
truncate table events;
INSERT INTO events (id, at, command, state, log) VALUES (21,'2009-11-12 21:11:04','{\"auction\":1234,\"bid\":334,\"account\":\"TESTUSER_puchyr\",\"exe\":\"echo\"}','INSERTED','');
INSERT INTO events (id, at, command, state, log) VALUES (22,'2009-11-12 21:12:29','{\"auction\":1234,\"bid\":359,\"account\":\"TESTUSER_puchyr\",\"exe\":\"false\"}','INSERTED','');
INSERT INTO events (id, at, command, state, log) VALUES (23,'2009-11-12 21:13:41','{\"auction\":1234,\"bid\":438,\"account\":\"TESTUSER_puchyr\",\"exe\":\"echo\"}','INSERTED','');
INSERT INTO events (id, at, command, state, log) VALUES (24,'2009-11-12 21:14:59','{\"auction\":1234,\"bid\":545,\"account\":\"TESTUSER_puchyr\",\"exe\":\"echo\"}','INSERTED','');
