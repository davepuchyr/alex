#!/usr/bin/perl
# $Id: procmailrc.pl 235 2008-10-05 19:36:15Z dave $

do { # pass-through if no ~/.procmailrc.pm
   local $/;
   exit !print <STDIN>; # print returns 1 on success
} if ( !-r '.procmailrc.pm' );

require '.procmailrc.pm';

my $head = '';
while ( my $line = <STDIN> ) {
   $head .= $line;
   last if ( $line eq "\n" );
}

my $f = onHeader( \$head );
exit $f->() if ( $f );

my $body = '';
while ( my $line = <STDIN> ) {
   $body .= $line;
   my $f = onBodyLine( \$line );
   exit $f->( \$head, \$body, \$line ) if ( $f );
}

exit !print $head . $body; # pass-through unhandled case

