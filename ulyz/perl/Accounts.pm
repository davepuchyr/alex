package Accounts;
my $Id = q|$Id: Accounts.pm 123 2010-11-06 00:57:58Z dave $|;

use strict;
use warnings;
use ENV;
use Utils;


my %accounts;
my $beenHere = 0;

&{ sub { # anonymous sub to init %accounts
   my $dbh = Utils::getDBH();
   my $siteclause = $ENV{EBAY_API_URL} =~ m|sandbox|i ? '' : 'NOT';
   my $eligibleclause =<<EOS;
AND max > -1
AND password != ''
AND banned = 0
AND site $siteclause LIKE '%sandbox%'
EOS
   my $sql =<<EOSQL;
SELECT DISTINCT a.*
FROM accounts a, windows w
WHERE a.account = w.account
$eligibleclause
EOSQL
   my $sth = $dbh->prepare( $sql ) or die $dbh->errstr;

   $sth->execute() or die $dbh->errstr;

   while ( my $r = $sth->fetchrow_hashref() ) {
      $accounts{lc( $r->{account} )} = $r;
   }

   $sth->finish() or die "couldn't finish: $sth->errstr\n";

   # WTF! This query, from phpMyAdmin, yields accounts that do NOT have windows
   #      but, in perl, yields accounts that have windows!
   $sql =<<EOSQL;
SELECT a.account
FROM accounts a
WHERE a.account NOT IN (
   SELECT DISTINCT account
   FROM windows
)
$eligibleclause
EOSQL

   $sth->execute() or die $dbh->errstr;

   my @ready;
   while ( my $r = $sth->fetchrow_hashref() ) {
      push( @ready, $r->{account} );
   }

   $sth->finish() or die "couldn't finish: $sth->errstr\n";
   $dbh->disconnect() or die "couldn't disconnect: $!\n";

   if ( scalar( @ready ) ) {
      my $ready = join( "', '", @ready );
      $sql =<<EOSQL;
there are accounts that are ready but lacking windows!; see WTF if Accounts.pm and execute

SELECT *
FROM accounts
WHERE account NOT IN ( '$ready' )
$eligibleclause 
EOSQL
      Utils::error( $sql );
   }

} }();


sub getAccountIds {
   my @accounts = keys( %accounts );

   return \@accounts;
}


sub getEligibleAccounts {
   my @accounts;

   foreach my $id ( sort( keys( %accounts ) ) ) {
      my ( $active, $max ) = ( $accounts{$id}{active}, $accounts{$id}{max} );
      my $eligible = $active < $max ? '' : 'NOT ';
      print "$id is ${eligible}eligible (active:max == $active:$max)\n" if ( !$beenHere );
      push( @accounts, $accounts{$id} ) if ( $active < $max );
   }

   $beenHere = 1;

   return \@accounts;
}


sub getIdleAccounts { # accounts that don't have active bids OR have a 0 max
   my @accounts;

   foreach my $id ( sort( keys( %accounts ) ) ) {
      my ( $active, $max ) = ( $accounts{$id}{active}, $accounts{$id}{max} );
      my $idle = ( !$active || !$max );
      my $eligible = $idle ? '' : 'NOT ';
      print "$id is ${eligible}idle (active:max == $active:$max)\n";
      push( @accounts, $accounts{$id} ) if ( $idle );
   }

   return \@accounts;
}


1;

