#!/usr/bin/perl -w
# $Id: bidder.pl 129 2010-11-24 02:52:59Z dave $

use strict;
use warnings;
use JSON::XS;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use ENV;
use Utils;


my %argv = %{+ JSON::XS->new->utf8->decode( $ARGV[0] ) };
my $account = $argv{$ENV{CMD_KEY_ACCOUNT}};
my $strategy = $argv{$ENV{CMD_KEY_BID_STRATEGY}};
my $dbh = Utils::getDBH();
my $sql =<<EOS;
SELECT site, password, proxy, email, epassword, agent, interests
FROM accounts
WHERE account ='$account'
EOS
my $sth = $dbh->prepare( $sql ) or die "couldn't prepare: $dbh->errstr\n";
$sth->execute() or die "couldn't execute: $sth->errstr\n";

my ( $site, $password, $proxy, $email, $epassword, $agent, $interests ) = $sth->fetchrow_array();

$sth->finish() or die "couldn't finish: $sth->errstr\n";

# clean values
chomp( $site );
chomp( $password );
chomp( $proxy );
chomp( $email );
chomp( $epassword );
chomp( $agent );
chomp( $interests );
$agent =~ s|\s+| |g; # eliminate newlines, coalesce whitespace
$interests =~ s|\s+| |g; # eliminate newlines, coalesce whitespace

my $graph;
if ( $strategy eq 'BidViaSearch' ) {
   my @delimited = split( /,/, lc( $interests ) ); # HARD-CODED
   Utils::shuffle( \@delimited );
   my $terms1 = join( ',', splice( @delimited, 0, 1 + int( rand( scalar( @delimited ) - 1 ) ) ) ); # HARD-CODED
   my $terms2 = join( ',', splice( @delimited, 0, 1 + int( rand( scalar( @delimited ) - 1 ) ) ) ); # HARD-CODED

   my $auction = $argv{$ENV{CMD_KEY_AUCTION}};
   $sql = "SELECT country, category, title FROM auctions WHERE id ='$auction'";
   $sth = $dbh->prepare( $sql ) or die "couldn't prepare: $dbh->errstr\n";
   $sth->execute() or die "couldn't execute: $sth->errstr\n";

   my ( $country, $category, $title ) = $sth->fetchrow_array();
   chomp( $title );
   $title =~ s|ulyz.*?\b| |gi; # remove ulyz and derivaties
   $title =~ s|\W+| |g; # eliminate newlines, coalesce whitespace
   $title =~ s|[[:punct:]]||g; # remove exclamation points, etc
   $title = lc( $title ); # make lowercase

   $sth->finish() or die "couldn't finish: $sth->errstr\n";

   my %tlds = (
      DE => 'ebay.de',
      ES => 'ebay.es',
      FR => 'befr.ebay.be',
      GB => 'ebay.co.uk',
      IT => 'ebay.it',
      NL => 'ebay.nl',
      US => 'ebay.com',
   );

   $site =~ s|ebay.*|$tlds{$country}|;

   @delimited = $title =~ m|(\w{4,}.*?) ?|go; # HARD-CODED
   Utils::shuffle( \@delimited );
   my $terms = join( ' ', splice( @delimited, 0, 3 ) ); # HARD-CODED

   # ebay.fr doesn't have a search field on all pages, so go to MyEbay.1 before BidViaSearch
   # Login -> Search.1 -> MyEbay.1 -> BidViaSearch -> MyEbay.2 -> Search.2
   $graph =<<EOS;
/domains/com/ebay/Login.1
/domains/com/ebay/Search.1
/domains/com/ebay/BidViaSearch.1
/domains/com/ebay/MyEbay.1
/domains/com/ebay/MyEbay.2
/domains/com/ebay/Search.2
/domains/com/ebay/Login.1.session->/domains/com/ebay/Search.1.session
/domains/com/ebay/Search.1.session->/domains/com/ebay/MyEbay.1.session
/domains/com/ebay/MyEbay.1.session->/domains/com/ebay/BidViaSearch.1.session
/domains/com/ebay/BidViaSearch.1.session->/domains/com/ebay/MyEbay.2.session
/domains/com/ebay/MyEbay.2.session->/domains/com/ebay/Search.2.session
/domains/com/ebay/Login.1.proxy="$proxy"
/domains/com/ebay/Login.1.referer=
/domains/com/ebay/Login.1.agent="$agent"
/domains/com/ebay/Login.1.user=
/domains/com/ebay/Login.1.host=
/domains/com/ebay/Login.1.recipients=
/domains/com/ebay/Login.1.id="$account"
/domains/com/ebay/Login.1.passwd="$password"
/domains/com/ebay/Login.1.ccTLD="$site"
/domains/com/ebay/Search.1.user=
/domains/com/ebay/Search.1.host=
/domains/com/ebay/Search.1.recipients=
/domains/com/ebay/Search.1.session=
/domains/com/ebay/Search.1.terms="$terms1"
/domains/com/ebay/Search.1.duration=300
/domains/com/ebay/BidViaSearch.1.item="$argv{$ENV{CMD_KEY_AUCTION}}"
/domains/com/ebay/BidViaSearch.1.bid=$argv{$ENV{CMD_KEY_BID}}
/domains/com/ebay/BidViaSearch.1.max=$argv{$ENV{CMD_KEY_BID_MAX}}
/domains/com/ebay/BidViaSearch.1.user=
/domains/com/ebay/BidViaSearch.1.host=
/domains/com/ebay/BidViaSearch.1.recipients=
/domains/com/ebay/BidViaSearch.1.session=
/domains/com/ebay/BidViaSearch.1.category=$category
/domains/com/ebay/BidViaSearch.1.terms="$terms"
/domains/com/ebay/BidViaSearch.1.duration=1
/domains/com/ebay/Search.2.user=
/domains/com/ebay/Search.2.host=
/domains/com/ebay/Search.2.recipients=
/domains/com/ebay/Search.2.session=
/domains/com/ebay/Search.2.terms="$terms2"
/domains/com/ebay/Search.2.duration=120
/domains/com/ebay/Login:/domains/com/ebay/Login.js
/domains/com/ebay/BidViaSearch:/domains/com/ebay/BidViaSearch.js
/domains/com/ebay/MyEbay:/domains/com/ebay/MyEbay.js
/domains/com/ebay/Search:/domains/com/ebay/Search.js
EOS
} elsif ( $strategy eq 'BidViaMyEbayActive' or $strategy eq 'BidViaMyEbayActiveUntilWinning' ) {
   $graph =<<EOS;
/domains/com/ebay/$strategy:/domains/com/ebay/$strategy.js
/domains/com/ebay/MyEbay:/domains/com/ebay/MyEbay.js
/domains/com/ebay/Login:/domains/com/ebay/Login.js
/domains/com/ebay/$strategy.1
/domains/com/ebay/Login.1
/domains/com/ebay/MyEbay.1
/domains/com/ebay/Login.1.session->/domains/com/ebay/MyEbay.1.session
/domains/com/ebay/MyEbay.1.session->/domains/com/ebay/$strategy.1.session
/domains/com/ebay/$strategy.1.user=
/domains/com/ebay/$strategy.1.host=
/domains/com/ebay/$strategy.1.recipients=
/domains/com/ebay/$strategy.1.session=
/domains/com/ebay/$strategy.1.item="$argv{$ENV{CMD_KEY_AUCTION}}"
/domains/com/ebay/$strategy.1.bid=$argv{$ENV{CMD_KEY_BID}}
/domains/com/ebay/$strategy.1.max=$argv{$ENV{CMD_KEY_BID_MAX}}
/domains/com/ebay/Login.1.proxy="$proxy"
/domains/com/ebay/Login.1.referer=
/domains/com/ebay/Login.1.agent="$agent"
/domains/com/ebay/Login.1.user=
/domains/com/ebay/Login.1.host=
/domains/com/ebay/Login.1.recipients=
/domains/com/ebay/Login.1.id="$account"
/domains/com/ebay/Login.1.passwd="$password"
/domains/com/ebay/Login.1.ccTLD="$site"
EOS
} elsif ( $strategy eq 'BidViaUrl' or $strategy eq 'BidViaUrlUntilWinning' ) {
   $graph =<<EOS;
/domains/com/ebay/$strategy:/domains/com/ebay/$strategy.js
/domains/com/ebay/Login:/domains/com/ebay/Login.js
/domains/com/ebay/$strategy.1
/domains/com/ebay/Login.1
/domains/com/ebay/Login.1.session->/domains/com/ebay/$strategy.1.session
/domains/com/ebay/$strategy.1.user=
/domains/com/ebay/$strategy.1.host=
/domains/com/ebay/$strategy.1.recipients=
/domains/com/ebay/$strategy.1.session=
/domains/com/ebay/$strategy.1.item="$argv{$ENV{CMD_KEY_AUCTION}}"
/domains/com/ebay/$strategy.1.url="$argv{$ENV{CMD_KEY_URL}}"
/domains/com/ebay/$strategy.1.bid=$argv{$ENV{CMD_KEY_BID}}
/domains/com/ebay/$strategy.1.max=$argv{$ENV{CMD_KEY_BID_MAX}}
/domains/com/ebay/Login.1.proxy="$proxy"
/domains/com/ebay/Login.1.referer=
/domains/com/ebay/Login.1.agent="$agent"
/domains/com/ebay/Login.1.user=
/domains/com/ebay/Login.1.host=
/domains/com/ebay/Login.1.recipients=
/domains/com/ebay/Login.1.id="$account"
/domains/com/ebay/Login.1.passwd="$password"
/domains/com/ebay/Login.1.ccTLD="$site"
EOS
} else {
   die "'$argv{$ENV{CMD_KEY_BID_STRATEGY}}' is not a know bid strategy!";
}

$dbh->disconnect() or die "couldn't disconnect: $!\n";
$dbh = undef;

print $graph;
$graph =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;

my $ua = LWP::UserAgent->new();
$ua->timeout( 600 ); # be patient
my $nmurl = "http://$ENV{NM_HOST}:$ENV{NM_PORT}/";
my $req = POST( $nmurl, [ h => 'j', a => 'g', j => $graph ] );
my $res = $ua->request( $req );

if ( $res->is_success ) {
   foreach my $line ( split( /\n/, $res->content ) ) {
      print "$line\n" if ( $line !~ m|nap| );
      Utils::updateActiveBids( $line, $account );
   }
}

exit( $res->is_success && $res->content =~ m|domains/com/ebay/Bid phase = SUCCEEDED| ? 0 : 1 ); # HARD-CODED

