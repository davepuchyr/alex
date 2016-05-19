#!/usr/bin/perl -w
# $Id: searcher.pl 127 2010-11-21 17:20:10Z dave $

use strict;
use warnings;
use JSON::XS;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use ENV;
use Utils;


my %argv = %{+ JSON::XS->new->utf8->decode( $ARGV[0] ) };
my $account = $argv{$ENV{CMD_KEY_ACCOUNT}};
my $dbh = Utils::getDBH();
my $sql =<<EOS;
SELECT site, password, proxy, agent, interests
FROM accounts
WHERE account ='$account'
EOS
my $sth = $dbh->prepare( $sql ) or die "couldn't prepare: $dbh->errstr\n";
$sth->execute() or die "couldn't execute: $sth->errstr\n";

my ( $site, $password, $proxy, $agent, $interests ) = $sth->fetchrow_array();

$sth->finish() or die "couldn't finish: $sth->errstr\n";
$dbh->disconnect() or die "couldn't disconnect: $!\n";
$dbh = undef;

# clean values
chomp( $site );
chomp( $password );
chomp( $proxy );
chomp( $agent );
chomp( $interests );
$site = 'befr.ebay.be' if ( $site eq 'ebay.fr' or $site eq 'ebay.be' );
$agent =~ s|\s+| |g; # eliminate newlines, coalesce whitespace
$interests =~ s|\s+| |g; # eliminate newlines, coalesce whitespace

my @delimited = split( /,/, lc( $interests ) ); # HARD-CODED
Utils::shuffle( \@delimited );
my $terms = join( ',', splice( @delimited, 0, 1 + int( rand( scalar( @delimited ) - 1 ) ) ) ); # HARD-CODED

my $graph =<<EOS;
/domains/com/ebay/Login.1
/domains/com/ebay/MyEbay.1
/domains/com/ebay/Search.1
/domains/com/ebay/Login.1.session->/domains/com/ebay/MyEbay.1.session
/domains/com/ebay/MyEbay.1.session->/domains/com/ebay/Search.1.session
/domains/com/ebay/Search.1.user=
/domains/com/ebay/Search.1.host=
/domains/com/ebay/Search.1.recipients=
/domains/com/ebay/Search.1.session=
/domains/com/ebay/Search.1.terms="$terms"
/domains/com/ebay/Search.1.category=
/domains/com/ebay/Search.1.duration=$argv{$ENV{CMD_KEY_DURATION}}
/domains/com/ebay/Login.1.proxy="$proxy"
/domains/com/ebay/Login.1.referer=
/domains/com/ebay/Login.1.agent="$agent"
/domains/com/ebay/Login.1.user=
/domains/com/ebay/Login.1.host=
/domains/com/ebay/Login.1.recipients=
/domains/com/ebay/Login.1.id="$account"
/domains/com/ebay/Login.1.passwd="$password"
/domains/com/ebay/Login.1.ccTLD="$site"
/domains/com/ebay/Login:/domains/com/ebay/Login.js
/domains/com/ebay/MyEbay:/domains/com/ebay/MyEbay.js
/domains/com/ebay/Search:domains/com/ebay/Search.js
EOS

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

exit( $res->is_success
   && $res->content =~ m!drilled into! # HARD-CODED in conjunction with Search.js
   && $res->content =~ m!(search expired)|(completed entire search)! # HARD-CODED in conjunction with Search.js
   ? 0 : 1
);

