#!/usr/bin/perl -w
# $Id: ghost.pl 126 2010-11-13 19:48:43Z dave $

use strict;
use warnings;
use eBayAPI;
use Decoder;
use Instigator;
use Scheduler;
use XML::DOM::XPath;

$| = 1;
#map { print "ENV{$_} => $ENV{$_}\n"; } sort( keys( %ENV ) );

#my $item = eBayAPI::AddItem( 'davepuchyr' );
#printf( "id = %s; start = %s; end = %s\n", '' . $item->findnodes( '//ItemID/text()' ), $item->findnodes( '//StartTime/text()' ), $item->findnodes( '//EndTime/text()' ) );

my %argv = %{+ ( scalar( @ARGV ) ? JSON::XS->new->utf8->decode( $ARGV[0] ) : {} ) };
my $developers = exists( $argv{developers} ) ? $argv{developers} : '';
$developers =~ s|\s||g; # filter whitespce
my @developers = split( /$ENV{DEVELOPER_DELIMITER}/, $developers );
exit !print "need at least 1 developer in JSON key 'developers' ARGV[0]; ARGV[0] == '$ARGV[0]'\n" if ( !scalar( @developers ) );

my $dbh = Utils::getDBH();
my $yyyyMMdd = substr( `date +"%Y-%m-%d"`, 0, -1 );
my @bid0_strategies = split( /$ENV{BIDDER_BID_STRATEGIES_DELIMITER}/, $ENV{BIDDER_BID_STRATEGIES_INITIAL} );
my @bidi_strategies = split( /$ENV{BIDDER_BID_STRATEGIES_DELIMITER}/, $ENV{BIDDER_BID_STRATEGIES_SUBSEQUENT} );
my @bidn_strategies = split( /$ENV{BIDDER_BID_STRATEGIES_DELIMITER}/, $ENV{BIDDER_BID_STRATEGIES_FINAL} );

foreach my $developer ( @developers ) {
   print '_' x 40 . " $developer " . '_' x 40 . "\n";
   #print eBayAPI::GeteBayOfficialTime( $developer )->findnodes( '//Timestamp/text()' ) . "\n"; next;

   # populate auctions.winner
   my $sold = eBayAPI::GetMyeBaySelling( $developer );
   my $sql = qq|UPDATE auctions SET winner = ?, price = ? WHERE id = ?|;
   my $sth = $dbh->prepare( $sql ) or die $dbh->errstr;

   foreach my $item ( $sold->findnodes( '//OrderTransaction/Transaction' ) ) {
      my $id = $item->findnodes( './Item/ItemID/text()' );
      my $account = $item->findnodes( './Buyer/UserID/text()' );
      my $price = $item->findnodes( './Item/SellingStatus/CurrentPrice/text()' );
      $sth->execute( $account, $price, $id ) or die $dbh->errstr;
      print "$account won $id for $price\n";
   }

   $sth->finish() or die $dbh->errstr;

   # get all items listed today...
   my $doc = eBayAPI::GetSellerList( $developer, "$yyyyMMdd 00:00:00", "$yyyyMMdd 23:59:59" );

   my %items;
   foreach my $item ( $doc->findnodes( '//ItemArray/Item' ) ) {
      my $id = $item->findnodes( './ItemID/text()' );
      $items{$id} = $item;
   }

   if ( !scalar( keys( %items ) ) ) {
      print "$developer no auctions found\n";
      next; # bail on this developer
   }

   # ...and filter them against those already handled
   my $ids = join( ', ', keys( %items ) );
   $sql =<<EOSQL;
SELECT id
FROM auctions
WHERE id IN ( $ids )
EOSQL
   $sth = $dbh->prepare( $sql ) or die $dbh->errstr;

   $sth->execute() or die $dbh->errstr;

   while ( my ( $id ) = $sth->fetchrow_array() ) {
      $items{ $id }->dispose();
      delete( $items{ $id } );
   }

   $sth->finish() or die $dbh->errstr;

   if ( !scalar( keys( %items ) ) ) {
      print "$developer no new auctions found\n";
      next; # bail on this developer
   }

   # get average prices
   $sql =<<EOSQL;
SELECT thumb, AVG(price), COUNT(*)
FROM auctions
WHERE price > 0
GROUP BY thumb
EOSQL
   $sth = $dbh->prepare( $sql ) or die $dbh->errstr;

   $sth->execute() or die $dbh->errstr;

   my %prices;
   while ( my ( $thumb, $price, $count ) = $sth->fetchrow_array() ) {
      $prices{$thumb} = $count >= $ENV{GHOST_MIN_SAMPLES} ? $price : 0;
      print "$thumb => $prices{$thumb}\n";
   }

   $sth->finish() or die $dbh->errstr;

   # persist the newly discovered auctions and filter
   $sql =<<EOSQL;
INSERT INTO auctions ( id, country, thumb, start, end, max, category, title )
VALUES ( ?, ?, ?, ?, ?, ?, ?, ? )
EOSQL
   $sth = $dbh->prepare( $sql ) or die $dbh->errstr;

   my ( $dmin, $dmax ) = ( $ENV{GHOST_MIN_DURATION} * 86400, $ENV{GHOST_MAX_DURATION} * 86400 );

   while ( my ( $id, $item ) = each( %items ) ) {
      my $max = Decoder::decodeDescription( '' . $item->findnodes( './Description/text()' ) );

      my $url = $item->findnodes( './ListingDetails/ViewItemURL/text()' ); # persist url?
      my ( $thumb ) = $item->findnodes( './PictureDetails/GalleryURL/text()' ) =~ m|.*/(.*)|;
      my $start = $item->findnodes( './ListingDetails/StartTime/text()' );
      my $end = $item->findnodes( './ListingDetails/EndTime/text()' );
      my $category = $item->findnodes( './PrimaryCategory/CategoryID/text()' );
      my $title = $item->findnodes( './Title/text()' );
      my $country = $item->findnodes( './Country/text()' );
      my $duration = Utils::toUnixTime( $end ) - Utils::toUnixTime( $start );

#      unless ( $thumb ) {
#         Utils::error( "$id: no thumbnail!" );
#         delete( $items{$id} );
#         next;
#      }

      $sth->execute( $id, $country, $thumb, $start, $end, $max, $category, $title ) or die $dbh->errstr;
      $item->dispose();

      unless ( $max ) {
         Utils::error( "$id: no max bid code found!" );
         delete( $items{$id} );
         next;
      }

      unless ( $dmin <= $duration && $duration <= $dmax ) { # filter on duration
         Utils::error( "$id: duration $duration is not between $dmin and $dmax!" );
         delete( $items{$id} );
         next;
      }

#      my $regex = eval { qr/$thumb/ };
#      if ( $@ ) {
#         Utils::error( "$id: $thumb is not a valid regex!: $@" );
#         delete( $items{$id} );
#         next;
#      }

#      if ( exists( $ENV{GHOST_ELIGIBLE_THUMBS} ) && !grep( /$thumb/, $ENV{GHOST_ELIGIBLE_THUMBS} ) ) { # filter on thumb
#         Utils::error( "$id: $thumb is not in ENV{GHOST_ELIGIBLE_THUMBS} of $ENV{GHOST_ELIGIBLE_THUMBS}!" );
#         delete( $items{$id} );
#         next;
#      }

      if ( exists( $ENV{GHOST_INELIGIBLE_COUNTRIES} ) && grep( /$country/i, $ENV{GHOST_INELIGIBLE_COUNTRIES} ) ) { # filter on thumb
         Utils::error( "$id: $country is in ENV{GHOST_INELIGIBLE_COUNTRIES} of $ENV{GHOST_INELIGIBLE_COUNTRIES}!" );
         delete( $items{$id} );
         next;
      }

      $items{$id} = { # reuse %items by replacing DOM nodes with hashes
         thumb => $thumb,
         start => $start,
         end => $end,
         max => $max
      };
   }

   $doc->dispose();

   #print "instigating bid wars\n";
   foreach my $id ( keys( %items ) ) {
      my ( $home, $away ) = Instigator::fight( $dbh, $id );

      if ( !defined( $away ) ) {
         Utils::error( "$id: less than 2 eligible accounts - can't start a bid war" );
         delete( $items{$id} );
         next;
      }

      $items{$id}{home} = $home;
      $items{$id}{away} = $away;
   }

   #print "scheduling\n";
   foreach my $id ( keys( %items ) ) {
      my ( $start, $end, $max ) = ( $items{$id}{start}, $items{$id}{end}, $items{$id}{max} );

      # bids
      print "$id/$items{$id}{home}->{account}: ultimate bid for home is $max\n";
      my $tmax = Scheduler::scheduleBids( $dbh, $items{$id}{home}->{account}, $id, $start, $end, $max, $max, \@bid0_strategies, \@bidi_strategies, undef, undef );

      my $average = exists( $prices{$items{$id}{thumb}} ) ? $prices{$items{$id}{thumb}} : 0;
      my $juice = $items{$id}{away}->{juice};
      my $limit = $juice * $average;

      if ( $limit < 1 || $limit > $max ) {
         $juice = 1. / $juice if ( $juice > 1 );
         $limit = $max * $juice;
      }

      $limit = int( $limit );

      print "$id/$items{$id}{away}->{account}: ultimate bid for away is $limit\n";
      Scheduler::scheduleBids( $dbh, $items{$id}{away}->{account}, $id, $start, $end, $max, $limit, \@bid0_strategies, \@bidi_strategies, \@bidn_strategies, $tmax );
   }
}

print '_' x 40 . ' Scheduler::scheduleLameSearches ' . '_' x 20 . "\n";
Scheduler::scheduleLameSearches( $dbh );

$dbh->disconnect() or die "couldn't disconnect: $!\n";

