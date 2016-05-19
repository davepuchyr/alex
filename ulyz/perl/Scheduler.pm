package Scheduler;
my $Id = q|$Id: Scheduler.pm 128 2010-11-21 23:53:36Z dave $|;

# Schedules commands in the events table according to the constraints in the windows table.

use strict;
use warnings;
use Accounts;
use JSON::XS;

# HARD-CODED
my @bid_intervals = ( 5, 5, 5, 5, 10, 10 ); # HARD-CODED: round-to values
# TODO: create a BidModel package
my @steps = ( 0., 0.25, 0.5, 0.75, 0.95 ); # HARD-CODED: boundaries on timing
my ( $x1, $y1, $x2, $y2 ) = ( 2. / 3., 0.9, $steps[-1], 1. ); # HARD-CODED: 90% of max bid at 2/3 duration; 100% at last step
my $slope = ( $y1 - $y2 ) / ( $x1 - $x2 );
my $intercept = $y1 - $slope * $x1;
my $f = sub { return $_[0] * $slope + $intercept; }; # HARD-CODED: linear model
# ~HARD-CODED


my %windows; # map of ebay accounts to windows
&{ sub { # anonymous sub to init %windows
   my @days = ( 0..6 );
   my $today = ( gmtime() )[6];

   if ( $today ) { # make today the first window
      my @front = splice( @days, $today );
      splice( @front, scalar( @front ), 0, @days );
      @days = @front;
   }

   my $dbh = Utils::getDBH();
   my $init = sub { # has to be a closure so that we can access $dbh and @days
      my $account = shift;
      my @windows;
      my @weekdays = qw( sun mon tue wed thu fri sat );
      my $sql =<<EOSQL;
SELECT start, end
FROM windows
WHERE account = '$account' AND day = ?
ORDER BY start
EOSQL
      my $sth = $dbh->prepare( $sql ) or die $dbh->errstr;
      foreach my $day ( @days ) {
         $sth->execute( $day ) or die $dbh->errstr;

         while ( my ( $opened, $closed ) = $sth->fetchrow_array() ) {
            $opened = Utils::toUnixTime( substr( `date +'%F %T' -u -d '$weekdays[$day] $opened'`, 0, -1 ) );
            $closed = Utils::toUnixTime( substr( `date +'%F %T' -u -d '$weekdays[$day] $closed'`, 0, -1 ) );

            push( @windows, $opened, $closed );
         }

         $sth->finish() or die $dbh->errstr;
      }

      die "$account needs entries in the windows table!" if ( !scalar( @windows ) );

      return \@windows;
   };

   map { $windows{ lc($_) } = $init->( $_ ); } @{+ Accounts::getAccountIds() };

   $dbh->disconnect() or die "couldn't disconnect: $!\n";
} }();



sub scheduleBids {
   my ( $dbh, $account, $auction, $start, $end, $max, $ultimate, $bid0s, $bidis, $bidns, $tmax ) = @_;
   my @bid0_strategies = @{+ $bid0s };
   my @bidi_strategies = @{+ $bidis };
   my @bidn_strategies = defined( $bidns ) ? @{+ $bidns } : ();
   my @windows = @{+ $windows{lc( $account )} };
   my $t0 = Utils::toUnixTime( $start );
   my $tf = Utils::toUnixTime( $end );
   my $duration = $tf - $t0;

   return Utils::error( "$auction: can't schedule bids because duration is greater than 1 week" ) if ( $duration > 604800 );

   $tmax = $tf - 3600 * $ENV{SCHEDULER_MIN_HOURS_TIL_END} - int( rand( $ENV{SCHEDULER_NUDGE} ) ) if ( !defined( $tmax ) ); # penultimate bid 4h or so from end
   $tmax += int( rand( $ENV{SCHEDULER_NUDGE} ) ) if ( defined( $bidns ) ); # ultimate bid time for bidder 'away'
   my @bid_times = ( $tmax );
   my ( $n, $m ) = ( scalar( @steps ) - 1, scalar( @windows ) );

   while ( --$n ) { # load up bid_times...
      my ( $upper, $lower ) = ( $steps[$n], $steps[$n - 1] );
      my $ti = int( ( ( $upper - $lower ) * rand() + $lower ) * $duration + $t0 );
      push( @bid_times, $ti );
   }

   for my $i ( 0 .. scalar( @bid_times ) - 1 ) { # ...and adjust for windows
      my ( $ti, $j ) = ( $bid_times[$i], 0 );

      next if ( $ti < $windows[$j] ); # too early

      while ( $j < $m && $ti > $windows[$j + 1] ) {
         $j += 2;
      }

      unless ( $windows[$j] <= $ti && $ti <= $windows[$j + 1] || $ti == $tmax ) { # nudge if not $tmax
          $ti = int( rand( $windows[$j + 1] - $windows[$j] ) ) + $windows[$j];
      }

      $bid_times[$i] = $ti;
   }

   # insert into table events
   my $now = gmtime();
   my $sql = qq|INSERT INTO events ( at, command, log, modified ) VALUES ( ?, ?, '[$now] inserted by $Id\n', NOW() )|;
   my $sth = $dbh->prepare( $sql ) or die $dbh->errstr;

   my $lastbid = 0;
   my $exe = $ENV{EXE_BIDDER};
   $exe = Utils::pwd() . $exe if ( $exe !~ m|^/| );
   ( $n, $m ) = ( 0, scalar( @bid_times ) );

   foreach my $t ( sort( @bid_times ) ) {
      my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = gmtime( $t );
      my $at = sprintf( "%4d-%02d-%02d %02d:%02d:%02d", 1900 + $year, 1 + $mon, $mday, $hour, $min, $sec );

      my $bid_strategy_ref = \@bidi_strategies;
      $bid_strategy_ref = \@bid0_strategies if ( ++$n == 1 ); # note increment
      $bid_strategy_ref = \@bidn_strategies if ( $n == $m && scalar( @bidn_strategies ) );
      Utils::shuffle( $bid_strategy_ref );

      my $strategy = $bid_strategy_ref->[0];

      my $bid = $f->( ( $t - $t0 ) / $duration ) * $ultimate;
      my $roundto = $bid_intervals[rand( scalar( @bid_intervals ) )];
      my $updown = rand() < 0.5 ? 0 : 0.5;
      $bid = $roundto * int( ( $bid + $updown * $roundto ) / $roundto );
      $bid = $max if ( $bid > $max );
      $bid = 1 if ( $bid <= 0 );
      $bid = int( $bid );

      next if ( $bid <= $lastbid );

      $lastbid = $bid;

      if ( $n == $m && !scalar( @bidn_strategies ) ) { # home's last bid
         $strategy = 'BidViaMyEbayActive' ; # HARD-CODED: set the floor
         $bid = $max; # HARD-CODED: make home's last bid == $max
      }

      $bid -= 10 if ( $strategy eq 'BidViaMyEbayActiveUntilWinning' ); # HARD-CODED

      my %command = (
         $ENV{CMD_KEY_EXE} => $exe,
         $ENV{CMD_KEY_WD} => Utils::pwd(),
         #$ENV{CMD_KEY_VERBOSE} => 1,
         $ENV{CMD_KEY_MAILTO} => $ENV{USER},
         $ENV{CMD_KEY_AUCTION} => $auction,
         $ENV{CMD_KEY_ACCOUNT} => $account,
         $ENV{CMD_KEY_BID_STRATEGY} => $strategy,
         $ENV{CMD_KEY_BID} => $bid,
         $ENV{CMD_KEY_BID_MAX} => $max
      );
      my $json = JSON::XS->new->utf8->encode( \%command );
      printf( "%s, %s\n", $at, $json );
      $sth->execute( $at, $json ) or die $dbh->errstr;
   }

   # reap 2-5 minutes after the end of the auction in order to update active bids
   $exe = $ENV{EXE_REAPER};
   $exe = Utils::pwd() . $exe if ( $exe !~ m|^/| );
   my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = gmtime( $tf + 120 + int( rand( 180 ) ) ); # HARD-CODED 2-5 minutes
   my $at = sprintf( "%4d-%02d-%02d %02d:%02d:%02d", 1900 + $year, 1 + $mon, $mday, $hour, $min, $sec );

   my %command = (
      $ENV{CMD_KEY_EXE} => $exe,
      $ENV{CMD_KEY_WD} => Utils::pwd(),
      $ENV{CMD_KEY_MAILTO} => $ENV{USER},
      $ENV{CMD_KEY_ACCOUNT} => $account,
      $ENV{CMD_KEY_AUCTION} => $auction
   );

   my $json = JSON::XS->new->utf8->encode( \%command );
   printf( "%s, %s\n", $at, $json );
   $sth->execute( $at, $json ) or die $dbh->errstr;

   $sth->finish() or die $dbh->errstr;

   return $tmax;
}


sub scheduleLameSearches {
   my ( $dbh ) = @_;
   my @accounts = @{+ Accounts::getIdleAccounts() };
   my $now = gmtime();
   my $sql = qq|INSERT INTO events ( at, command, log, modified ) VALUES ( ?, ?, '[$now] inserted by Scheduler::scheduleLameSearches\n', NOW() )|;
   my $sth = $dbh->prepare( $sql ) or die $dbh->errstr;
   my $exe = $ENV{EXE_SEARCHER};
   $exe = Utils::pwd() . $exe if ( $exe !~ m|^/| );

   Utils::shuffle( \@accounts );
   splice( @accounts, int( scalar( @accounts ) / 2 ) );

ACCOUNT:
   foreach my $href ( @accounts ) {
      my $account = $href->{account};
      my $t = time() + int( rand( 43200 ) ); # HARD-CODED: within 12 hours
      my @windows = @{+ $windows{lc( $account )} };
      my ( $i, $n ) = ( 0, scalar( @windows ) );

      while ( $i < $n ) {
         if ( $windows[$i] <= $t && $t <= $windows[$i + 1] ) {
            my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = gmtime( $t );
            my $at = sprintf( "%4d-%02d-%02d %02d:%02d:%02d", 1900 + $year, 1 + $mon, $mday, $hour, $min, $sec );
            my %command = (
               $ENV{CMD_KEY_EXE} => $exe,
               $ENV{CMD_KEY_WD} => Utils::pwd(),
               $ENV{CMD_KEY_MAILTO} => $ENV{USER},
               $ENV{CMD_KEY_ACCOUNT} => $account,
               $ENV{CMD_KEY_DURATION} => int( 120 + rand( 300 ) ) # HARD-CODED duation between 2 and 7 minutes
            );
            my $json = JSON::XS->new->utf8->encode( \%command );
            printf( "%s, %s\n", $at, $json );
            $sth->execute( $at, $json ) or die $dbh->errstr;
            next ACCOUNT;
         }

         $i += 2;
      }

      print gmtime( $t ) . " is not in any of ${account}'s windows\n";
   }

   $sth->finish() or die $dbh->errstr;
}


1;

