#!/usr/bin/perl -w

use strict;
use Instigator;

my $dbh = Utils::getDBH();
my %battles = %{+ Instigator::getBattles( $dbh ) };

foreach my $battle ( sort( keys( %battles ) ) ) {
   print "$battle = $battles{$battle}\n";
}

$dbh->disconnect() or die "couldn't disconnect: $!\n";
