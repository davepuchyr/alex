#!/usr/bin/perl

use strict;
use warnings;
use XML::DOM;
use XML::DOM::XPath;
use utf8;
use ENV;
use Utils;
use JSON::XS;
#use Scheduler;
use eBayAPI;

my %argv = %{+ JSON::XS->new->utf8->decode( $ARGV[0] ) };
#my $sold = eBayAPI::GetMyeBaySelling();
#
#foreach my $item ( $sold->findnodes( '//OrderTransaction/Transaction' ) ) {
#   my $id = $item->findnodes( './Item/ItemID/text()' );
#   my $account = $item->findnodes( './Buyer/UserID/text()' );
#   my $price = $item->findnodes( './Item/SellingStatus/CurrentPrice/text()' );
#   print "$account won $id for $price\n";
#}

my $yyyyMMdd = substr( `date +"%Y-%m-%d"`, 0, -1 );
my $doc = eBayAPI::GetSellerList( "2010-09-05 00:00:00", "$yyyyMMdd 23:59:59" );

Utils::prettyPrintXML( $doc );

