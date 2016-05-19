package Instigator;
my $Id = q|$Id: Instigator.pm 118 2010-10-09 19:08:14Z dave $|;

# Chooses the home and away entries for a row in the auctions table.
# Assumes that the thumbnail is unique for a given product.

use strict;
use warnings;
use Accounts;


sub fight {
   my ( $dbh, $id ) = @_;

   my @accounts = @{+ Accounts::getEligibleAccounts() };
   Utils::shuffle( \@accounts );

   my ( $home, $away ) = ( $accounts[0], $accounts[1] );

   if ( defined( $home ) && defined( $away ) ) {
      ++$home->{active};
      ++$away->{active};

      $dbh->do( qq|UPDATE accounts SET active = $home->{active} WHERE account = '$home->{account}';| ) or die $dbh->errstr;
      $dbh->do( qq|UPDATE accounts SET active = $away->{active} WHERE account = '$away->{account}';| ) or die $dbh->errstr;
      $dbh->do( qq|UPDATE auctions SET home = '$home->{account}', away = '$away->{account}' WHERE id = $id| ) or die $dbh->errstr;
   }

   return ( $home, $away );
}


sub getBattles { # aka histogram
   my $dbh = shift;
   my $sql =<<EOSQL;
SELECT home, away
FROM auctions
WHERE home != ''
EOSQL
   my $sth = $dbh->prepare( $sql ) or die "couldn't prepare: $dbh->errstr\n";

   $sth->execute() or die "couldn't execute: $sth->errstr\n";

   my %battles;
   while ( my ( $home, $away ) = $sth->fetchrow_array() ) {
      ++$battles{ $home lt $away ? "$home vs $away" : "$away vs $home" };
   }

   $sth->finish() or die "couldn't finish: $sth->errstr\n";

   return \%battles;
}


1;

