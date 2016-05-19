package eBayAPI;
# $Id: eBayAPI.pm 120 2010-10-10 17:47:05Z dave $

use strict;
use JSON::XS;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Headers;
use XML::DOM;
use Utils;
use ENV;

my $ua = new LWP::UserAgent();
my $parser = new XML::DOM::Parser();
my %developers = (
   captainblueskyDE => { # Llull7038
      DEVID => 'a80c99ea-6f87-4ff8-b934-3d2d2d1f0e70',
      AppID => 'BigboxRe-1ee1-45db-87f6-b1edc1be5924',
      CertID => 'b8ce7276-870a-403d-b9a3-f78bab875030',
      token => 'AgAAAA**AQAAAA**aAAAAA**PkiOTA**nY+sHZ2PrBmdj6wVnY+sEZ2PrA2dj6wNkoOlCpSLqQidj6x9nY+seQ**ZvIAAA**AAMAAA**TVBT+51gzQ+SQ+Aw4GRUWxw/sLOsOPbIuUH/C7T9fFv/cIhgVbDZQwI9/JGXubMz4jZ4pH1DdSVwU1A92ahLtjYcgccYmToTG6ooPV7v/J/dnKd+eYZoDRZVO5XVia7F5rWSJWLrl9xvcPZapdAHioYySb64nrFxaF9XpQMysoAjPHZiuyWgtu5IGGMpDBqRNVmAT3+6b/6Ofjg6Fxt7JCvve00KkVpZo2y5dzLAnZJG9m3ThZPG7KI6ccZ0P0OPunF8eKj8ML8XKt9rS1E0lH8Vv69y2525aGgQ5FWhzgeQ0HvCo1Hr+w4ajtBRPP7S0k2AMDb45ULZ9uZ0E446tMcP5UXxPwGpb7VCRxXQy2BkTlbCz5ctFsQDuLyoUCP4GULEEeNPtPugXue3HUJ2RvpJMi8khtIsslUwmUG6dLZwYGOUa8cqyLTqcCID137LOItDuHslPyVOQpYc4/Ncb4mFKSo2kwpzKQI3a0BpisUPoo/oUFF2h8O899+0np6+6itn/MqyG6TlVGaDLBFNEcZBVtXtSqn+xCIjPrjiOhcRTNViYEa3Xb11AoUIY44aDxJJ554+C0ieEnAn2SuKQihYIk70Q9KHccTaWAtkaIWltNd0ZssH7ONmY3s/G7DhIzXm6pyl9r5YSVxqrlkdZOr6ukMOGfuZ0R3UGHmucIv0uZ7QREbfkGXoArHfUI+WDCjNq2G9mquBA+S+w4SkmP2lZcF0TvpY+yzeWeNfiN5apJ8cPIL7s6tUCkYpqHiY',
      seller => 'captainbluesky-deutsch'
   },
   captainblueskyES => {
      DEVID => '2e1217d3-b3a8-4fb2-9d31-64bfd058608f',
      AppID => 'BigboxRe-7cbd-40dd-8621-e005597d11d3',
      CertID => '4a1b7bbd-db31-41f8-81e3-b4e45f4800f5',
      token => 'AgAAAA**AQAAAA**aAAAAA**CE6OTA**nY+sHZ2PrBmdj6wVnY+sEZ2PrA2dj6wNkoOlCpWFpQudj6x9nY+seQ**aPIAAA**AAMAAA**O0GhIQItNLoTsw3E294+HGWT25HxSnFm0p3Romz3YbPh70R5/PF78SGWvpCBHOlC8mvL25GCnx0i5AeAqPF2ItGWUZyYH2Kp7p2PttUzsnNVNsN+El8brYiFUitPGrJikpBCQLLa73ts4ZoINnLgKZojmFPjwcIOLBUweYdjQxI4BxvDXt6x86W9pDb7LvSX5a6gunAQ+4097XGWssdAdU1IynmWKCxMTspck2PvT427a+hNvXCYTeVLDyVeXLW0t7FnskaT7g1+ZI1nWpw6S9D+wmKNUdfhhF7tby7gmqc7eIxh6ZRuoannI7EX68+SmTumgXOmpM21NVGNbDj7+UCQ94fJLcXcCzwHqWpK1EY01F5ygFAGMtLrOOuCoZ68CSg47lE0qqhfbqvJnvXfbSukftuleULmbkmyhAOy1lKT17VpgSFrNesnbR5FM/spz/I3Gvi0VlubdMwX0AwG5n7c7MDenkaQ1PbRK0242AMfWPP8BANRFCV3aqQH2cyNorijOFOL4Pb67HQ4mUPKjIJJjSVOKUlnYAPzwiN6hBlSPXCn3TWOqSKkmz6BdNd0yzI1CcBvQytkxCnr74HZ6cLL6NW004ju7XyRB6a5JfK/aLqHRCTlFFjwbqd5+KESvu7BXeDyFkEOinT68Ylo4tGcPbDGMZLusN0IXPNPdkrKp5UYlt8Wir+7RY+Biuw5A5SSdqd2EzZTL86vR08cpR4aWvLNj1/2T/NIawH2MilKBoIO5zV40JV2IXP2o/8x',
      seller => 'captainbluesky-espanol'
   },
   captainblueskyFR => {
      DEVID => '25469c67-b0bf-440d-a42b-0f089c9f36ac',
      AppID => 'BigboxRe-d26b-4fa0-9ca2-0aac58e9d96a',
      CertID => '458a45de-4918-405e-bf29-eea2e0ff9ed2',
      token => 'AgAAAA**AQAAAA**aAAAAA**v1COTA**nY+sHZ2PrBmdj6wVnY+sEZ2PrA2dj6wNkoOlCZWAogWdj6x9nY+seQ**afIAAA**AAMAAA**iOEZqk1furFvvB0TMmQodMvTIcb803BEQEQNjBKJt6n55YdWGYDKW9pV58t9ftAs4/tH2a40s9RY1BF7CfWm1PEgKK54/0CyrKXfrQFUk+zwWB4XPkwRb5Fw8iu1ZtwuEOR/mt+rHbC15L4URfVU53Mo6vIb22tzcx2TXOvu69gXT4XN75GB+zwsngqqCB5tJBCmtn86qpZMnu7lwbpC2llsOzYid9UJ7z1pmJAkQVVxT24iHNXVBTPP4Et5eHgFLEWfZDJiTb59mIFbcFmSLA8/1nFdVfL+Yy/hDSLutyX+f1orIua1HYPbPLuzzesMNnNfnFJQAkdutZh/Y1wQy/i/s1OzD8ykta5at4S20cxoFL5i9T6snZLQvWmEwA6BtILAB0LufdjCLypqjkQTPeTSaEFwsvVJLXA8SQ00k1YI+34beD2JHGMSuP3kZHfXmFIWvKHnGfRC8YPQGzPfG+P7Roxzx40XVwHtFZ3f5P/6o2J6fGKjB1yBPeX5vvDwv2CF8k5+tJK92MUd2qz0Fuzj3ae+yxJ6sCr8dTxVKNhWHSXp69cdDPzW0i2dL2hnKhoTCnciJQm2BhPgItNT/DskUjAPJ4VLZcXYN/SNo0NbcH1anApqQ8ZOQdyNdPnFCoAw56FuVEjJjCWh2D1FwGd/X7EWwaxMBh1WFv84ivgNbbatkiou95yCUSZD7Gv+1pMojIiS5W+GwWMsa3Dt5a6QkHVoZdjBDjjwZ87XgYifOa4ETW/tfWw8XEJccMTF',
      seller => 'captainbluesky-francais'
   },
   captainblueskyIT => {
      DEVID => 'dd2b94ac-3b8c-4714-921f-55c4e2c9e0eb',
      AppID => 'BigboxRe-b0be-4d4d-964b-649f55e57161',
      CertID => '88c391b9-7fb0-4584-938a-66d7cd7019b6',
      token => 'AgAAAA**AQAAAA**aAAAAA**q1WOTA**nY+sHZ2PrBmdj6wVnY+sEZ2PrA2dj6wNkoOlCpSCqQWdj6x9nY+seQ**avIAAA**AAMAAA**bRfTDlp/lylaM227Kb8Xy/RT1cJFerLAxEKR7F7pNNS6ookJE1xqa6Z2wC6ycM+UKrIr873UtR+2/oOr7M/loVVhFjtTMGXLqrORiwuridTjLNthlYQ/CsSmj4MnZA65EoyK1KG9lv5Fr5xJAmAhO0xWStZhuSHoK8iZ3lSlMv/nbZ54zzOsOClL7bWpK+m/SfUWecAbsF6fWxFM0H7E61ZxaDwUd7wWwTCvExLsQk1FfMD3YhS4LgTI2nX1kgSNWxG4/+j6igY7+EGcvrYw/da8hrWCFZn5aQxhpJJAc9YRbnzD5WnD4EkMB0Dbcnwk0Ukiadp2URCtZRYmEYktasNgqRKZ+1kuPqtDtkqO+krJ+LBmPqCX2N9il7jVYgfr1WIeCIYviJCjsrzOX8LASRnzSUEaRJxEJ8MdlMDd+Lu7lTYY3urmpRvC4fJec+81yvo7jnSqoJv36z2Arf02oy9hjQcEvlaTqzQzDYwFVVqBUx0trRx/O/Uho9IlfoFJWPy8kJ53Q/y7gVxYmVTwCGMGxIS8ULhiCHxH97AQNZ75SsStEn8/3k//hnID5g1qNWNNIPuo3pal+Ses/UQe/UaJ379bK+Rn9QAnZOuNO+t1OKfI3MHZ4bceGYyFsU0HA4IIQftCLVBOAp6dRHGdCnTNBD7NUFg0n6FM0xu51Oait6z+k2yUaYP4oUI3+5NGlEiZvyqJ28okSGIYirzhewnPwkNNT4kTyF/QpyxM/qI/v0qgwoOR86QujKf80OXA',
      seller => 'captainbluesky-italiano'
   },
   mandla => {
      DEVID => '666d1e63-4725-4533-8bd7-0d696ee964b8',
      AppID => 'Alexande-08fd-437a-bad7-2268b7a1549c',
      CertID => '9e849c79-943c-4c88-9c75-69be1b43cd23',
      token => 'AgAAAA**AQAAAA**aAAAAA**WTgaSw**nY+sHZ2PrBmdj6wVnY+sEZ2PrA2dj6wJloanAZaHoQmdj6x9nY+seQ**18IAAA**AAMAAA**JvM0mqTK93B8zqW2V17H1RjehTw9/fQ31Xm+6UO4MjRGAkDb5EkiPPbKfYQZ9wTP5EtarHe33p4B8MDw/hPNT12Vzeh7jrTij7n05hhJHsd3qNMdXbNOBS8rNZG4v4g4/X4dIgGPJcaroD7J8CPa2CEb3Ubp5jjtSk1rtw9q3TLKYFsl+75iY6E/+96zJ0WIXgyac2cKA+Q+b6kV8H0ZqfhbBXtcBxvfq/m9s/P7/36/46lXNUMStcvGxH6uFi1fjyIz4HP0oEN7QI1T4C4VfzHR5FFAMtq8wP1/NVEJd75i7wxMLIchjYLvCD9TDFf45lODWuFbANaTm1cKLDwgSCFuagoN03Ypo1y8Yd39KqZ562Sclg17sDpd0wL1SCByR0XriMMPKAFPpGxnREG4Ews3CcWPdaORzpur3F0NWuDveRka1dhG4t0pgP7cZ7EdDr927uZBnY2iwsvRAp/PcEPd5r5ERu20Dxq25X8CpY4RRILqLAkvBi6XLZS88eGNE7d8GZxfA9LD1P21LwoFzt51P8cJ8dynusg6nlTs/T3sAvD/GmFql/4lTa1CDMSyxpQX/mKvVJgEjH8SJKyTqnJSom++P2ASzR3PhkCppFsf0bUlyuNZ5OoaniOfFLm9Rq8ldmaCtwHj2CrC6ZITiSpN2x7TinEiEWIxYI0qXHOekeQLOji3Bl3YkuUQwim2KedNgVt3nLwgY4X+6aszlnqX6uxyCmTbMWtbAHbFw2jTpcV+AkyE54GgRfkiFSUY',
      seller => 'captainbluesky'
   },
   ociobarato => {
      DEVID => '0d08f7c1-f68f-4bc6-bdc2-cf6a7163c999',
      AppID => 'BigboxRe-7ea2-4663-9892-38796268ecf4',
      CertID => '3a46678c-d066-4eef-9f5d-afb1c7c0bff0',
      token => 'AgAAAA**AQAAAA**aAAAAA**v1eOTA**nY+sHZ2PrBmdj6wVnY+sEZ2PrA2dj6wMloCpDZCEoA6dj6x9nY+seQ**a/IAAA**AAMAAA**M9L8ebFg8KTw2WGXvg95E/5S2ReT/LtKW3omjaLBJGs+Iq6KFX01CPD9HhNYV+FPbrnx5mpSt54ivc4t56xdDTOTDETbG4MvDlIdAWpKiXMuhCwBQzilqQiyalVRP/31F+edm/5R8JSVdP6c81d6+IUVhcSa50VgMasbr+6KSepGfS5O/SF/3c/E9anaUiMme5vASYL4zTdm5+WkjdADvPnN+BDlLGpHGR//Llta3Ue19hqS/LNHMWF7dFcm1qfGpzG1zAdHstzIij/MECuJH5wxyhZL0YE5ZZfNMfneTUfCaG4RsAA1oHQqdJu1LyxmrA3nzns36K4WrKK470+/r10g7Jeh6dstNzl16ygV5+roYvHOX/Pw2z0+Lt4GdTr8GdRcGuE+tY6Ll+jYFXeMfdo2Jdbtuo7k3OTnQK0//S5RxcJG3qHDSUTUfBYOk0mRrudsYxlOIVos6c1HdePuF3IsSY1P2w+sPuYYyWgQkrD3ZUFFku4rkilUNpsy+CokcibneDfeus58kh1x1JGnvXu1p1/hv1DqFdguwPZPRY5NXOi2+ZThJBb186YI0JzbyfXcVe3EAiqax+HJhxbCCJBx8JyELgg0TnXNs3fyezi6WviQ7ftky7WT9X8Uf5DS87PmLDOlT/lyefNcXnmElbL3iPLfH8v6XqXWK4CwTqJETfZP8jWXMW7Ne+S/iD9wQMwml8bRC32xyI/NRXw0EBWDYcsXc5oHM/JNp0UzStF8UxV9LUqeiCZnb2x5Xioc',
      seller => 'ociobarato'
   },
   xcgold => {
      DEVID => '2134-cf35-4908-a73f-06dda999ebf5',
      AppID => 'BigboxRe-df57-4881-92f2-37a40d39e7ab',
      CertID => '0a3f244b-c261-4f07-80ef-52ae663bde34',
      token => 'AgAAAA**AQAAAA**aAAAAA**Y1qOTA**nY+sHZ2PrBmdj6wVnY+sEZ2PrA2dj6wJl4KiAZSFpASdj6x9nY+seQ**bfIAAA**AAMAAA**kxOOtDDFmLTTb19+OqgWsmDAPS3ywmGtNytt8qe5wxuD0PEq5qVFtCuRdRR1zq1Doe4IFqaHQOKTUV5YeiwRnPFwtqyUulntgycDtAJGj/QcOq3aP//GYwiATV5+sNQELrvGG0jqeisMqdbP/SWyVo9/GqV7cJbdikUKvGFlXWeZspUrPe5uHrYDYFXD/pKkSKfRgrILgJl7J8mcLg8gNkezWXGksxq5g1cL387Hx58Okmy3yubvxoZAeif/4tCD8EEK4dVjpMPdPs7L0w4fcGbCOUigRyU8y8wg1dmt0ddFAODfiJ7XYsZ6LSjrRlud8894DUYm4QOQw0+QOeGb8bI/KnYQ5N/ccrnrS9+Vpz/28LfQ6upAeRFhxT0TYDesnI6WWZtqaYeuHG8+OUCxXTU80XKu1WQJ2YhoXXoK6X8/dAuGp0xJmL5d+Naht8XvNqSQ8Dj3ZC9PUZh96ncFbJb3xzF4vKhKDgkp7iE91pdKWrXpeTAe9gjRbXmBEOOZ1845Yb6s0CKtR8CSKwWFJh4v2MC/ObhWgBrsGjyy4j6kMc7GCPmxGlphLmeMDa54SPE6CCBe6RRs/npdYN7bqIUxNNWq1GQeZlJAL8v/Nx7ocqN/XhmvIS8AHIIaRaizHVqzoukeqvgl3Gi3lSks2b67BrNcRTGv89lqfWxslfLiNf4Orz5qDxAyTvOf04b9Gp1bgJt/Q4X4k9V2Xs6sKvGB+1U1Tf0iCFu1abry4W2eP9mJtLaTDIVv7g8MDVpB',
      seller => 'xcgold'
   },
   davepuchyr => { # davepuchyr/nyc apt first letter capitalized
      DEVID => '87fc46bb-2e73-4339-859e-323bc6b427d6',
      AppID => 'DavePuch-5405-4feb-bd32-c9df96182086',
      CertID => '0ea335ca-b855-4198-8609-c731b3fd7fb2',
      token => 'AgAAAA**AQAAAA**aAAAAA**GJbtSg**nY+sHZ2PrBmdj6wVnY+sEZ2PrA2dj6wFk4CoD5aGoQydj6x9nY+seQ**3DcBAA**AAMAAA**yelYfxkVM1M4Kmykz1RMzUmvKLDBf9jYPbVK1E6UJw7uvMYEaBM9mZmpWwFanme9WZfHziLC/zscaun7pe6lB6D7CtoVDj9BYUy4tlbKoZ0Ne6OklfN9wld2gmZd708T3MJWWR7E5x1sVPUYlPugCNmJoPFFdbbaZQdTfz1oi/JVcSaj3GfajT7TI1Zs0+esLwYnNWIfKB2SIU+0/ybQfIUT4ctfxQRDnu/JSXhQkVENLual77lSlZL6lnEaWoVSUCTblgHfDaNusB5E9f13/32XZt3HpUFfi18PueNLJBumBxpGZDITe7uVv/7Fc6E8LGD7645JqQr1i0f4LttvtyCLrPJmDcQQDMJ5Ts4gIk9JYodvLbh5SMSYwbhl6Hh8VVaZ6OF9XYMShiQsTVabXD0uqo5zfzsPYZxlpTN5lWWPZgdGWjVthQt2BWUgd59gK3P+vKNySeOgLR0KZojuBPltACzaSCHLYA4pCL46Rzc1ERCpUAITkfVr0guIniDU8Y9Eqk0y3UuTq1m/xe5M8fCme6/8XZDWN7TtcBjQb8gVegoSlyUz2brFCUqrwAKF6OrX4Q9OL51XD2Jm6NvvY5ogWvCGcBU28gtLYi+bbymC7/ca2DJHwzytKlqdG3t+HXSdbKp5Ei/EQ6PO0QpQvad7fN4tcr3RF/5HkFsgovvPMVjYh9H5XT2+bwNJwlBRqKhsUXNXyS+3s3rdc9JeMwY0HdKMr/wGkb4z9+eNmqpFW0sUJrSqPkSal0LEyXi/', # TESTUSER_puchyr/nyc apt first letter capitalized
      seller => 'TESTUSER_puchyr'  # TESTUSER_puchyr/nyc apt first letter capitalized
   },
);
my %argv = %{+ ( scalar( @ARGV ) ? JSON::XS->new->utf8->decode( $ARGV[0] ) : {} ) };
my $developers = exists( $argv{developers} ) ? $argv{developers} : '';
$developers =~ s|\s||g; # filter whitespce
foreach my $developer ( split( /$ENV{DEVELOPER_DELIMITER}/, $developers ) ) {
print "checking devloper $developer\n"; # dmjp
   exit print "'$developer' is not in the list of eBayAPI::developers: " . join( ' ', sort( keys( %developers ) ) ) . "\n" if ( !exists( $developers{$developer} ) );
}


sub requestAndParse {
   my ( $header, $xml ) = @_;
   #print $xml;

   $ua->proxy( [ 'http', 'https' ] => $ENV{EBAY_PROXY} ) if ( exists( $ENV{EBAY_PROXY} ) ); # set it every time just to be safe
   my $req = HTTP::Request->new( 'POST', $ENV{EBAY_API_URL}, $header, $xml );
   my $res = $ua->request( $req );

   die $res->error_as_HTML if ( $res->is_error );

   my $doc = $parser->parse( $res->content );
   my $errors = $doc->getElementsByTagName( 'Errors' );
   #print $res->content;

   if ( $errors->getLength() > 0 ) {
      Utils::prettyPrintXML( $doc );
   }

   return $doc;
}


sub getHeader {
   my ( $developer, $call, $site ) = @_;
   $site = 0 if ( !defined( $site ) );

   my $DEVID = $developers{$developer}{DEVID};
   my $AppID = $developers{$developer}{AppID};
   my $CertID = $developers{$developer}{CertID};
   my $token = $developers{$developer}{token};
   my $seller = $developers{$developer}{seller};

   my $header = HTTP::Headers->new();
   $header->push_header( 'Content-Type' => 'text/xml' );
   $header->push_header( 'X-EBAY-API-COMPATIBILITY-LEVEL' => '551');
   $header->push_header( 'X-EBAY-API-DEV-NAME' => $DEVID );
   $header->push_header( 'X-EBAY-API-APP-NAME' => $AppID );
   $header->push_header( 'X-EBAY-API-CERT-NAME' => $CertID );
   $header->push_header( 'X-EBAY-API-CALL-NAME' => $call );
   $header->push_header( 'X-EBAY-API-SITEID' => $site );

   return $header;
}


sub GeteBayOfficialTime {
   my $developer = shift;
   my $token = $developers{$developer}{token};
   my $header = getHeader( $developer, 'GeteBayOfficialTime' );

   my $xml =<<XML;
<?xml version='1.0' encoding='utf-8'?>
   <GeteBayOfficialTimeRequest xmlns="urn:ebay:apis:eBLBaseComponents">
   <RequesterCredentials>
      <eBayAuthToken>$token</eBayAuthToken>
   </RequesterCredentials>
</GeteBayOfficialTimeRequest>
XML

   return requestAndParse( $header, $xml );
}


sub GetSellerList { # http://developer.ebay.com/devzone/xml/docs/Reference/eBay/GetSellerList.html
   my ( $developer, $StartTimeFrom, $StartTimeTo, $UserID ) = @_;
   my $token = $developers{$developer}{token};
   my $seller = $developers{$developer}{seller};
   $UserID = $seller if ( !defined( $UserID ) );
   my $header = getHeader( $developer, 'GetSellerList' );
   my $xml =<<XML;
<?xml version="1.0" encoding="utf-8"?>
   <GetSellerListRequest xmlns="urn:ebay:apis:eBLBaseComponents">
      <RequesterCredentials>
         <eBayAuthToken>$token</eBayAuthToken>
      </RequesterCredentials>
   <DetailLevel>ItemReturnDescription</DetailLevel>
   <Pagination>
      <EntriesPerPage>200</EntriesPerPage>
   </Pagination>
   <StartTimeFrom>$StartTimeFrom</StartTimeFrom>
   <StartTimeTo>$StartTimeTo</StartTimeTo>
   <Sort>2</Sort>
   <UserID>$UserID</UserID>
</GetSellerListRequest>
XML

   return requestAndParse( $header, $xml );
}


sub AddItem { # http://developer.ebay.com/devzone/xml/docs/Reference/eBay/AddItem.html
   die "AddItem is not available for $ENV{EBAY_API_URL}." if ( $ENV{EBAY_API_URL} eq 'https://api.ebay.com/ws/api.dll' );
   my ( $developer, $site ) = @_;
   my $token = $developers{$developer}{token};
   my $header = getHeader( $developer, 'AddItem' );
   my $now = time();
   my $paypalEmail = 'magicalbookseller@yahoo.com';
   my %sites = (
      NL => {
         site => 'US',
         currency => 'USD',
         country => 'NL',
         zip => '80336'
      },
      ES => {
         site => 'US',
         currency => 'USD',
         country => 'ES',
         zip => '08002'
      },
      IT => {
         site => 'US',
         currency => 'USD',
         country => 'IT',
         zip => '00187'
      },
      UK => {
         site => 'UK',
         currency => 'USD',
         country => 'GB',
         zip => 'NW6 5RP'
      },
      US => {
         site => 'US',
         currency => 'USD',
         country => 'US',
         zip => '95125'
      },
   );
   my %site = %{+ $sites{UK} };
   #my $IJKL = sprintf( "%02d%02d", 99 * rand(), 99 * rand() );
   my $IJKL = sprintf( "%02d%02d", 8, 50 ); # 400
   my $xml =<<XML;
<?xml version="1.0" encoding="utf-8"?>
<AddItemRequest xmlns="urn:ebay:apis:eBLBaseComponents">
  <RequesterCredentials>
    <eBayAuthToken>$token</eBayAuthToken>
  </RequesterCredentials>
  <ErrorLanguage>en_US</ErrorLanguage>
  <WarningLevel>High</WarningLevel>
  <Item>
    <Title>$now is now</Title>
    <Description><![CDATA[
      This is the fifth book in the Harry Potter series. In <b>excellent</b> condition!
      <span id='sku' style='display:none;'>20091023-$IJKL</span>
    ]]>
    </Description>
    <PrimaryCategory>
      <CategoryID>377</CategoryID>
    </PrimaryCategory>
    <CategoryMappingAllowed>true</CategoryMappingAllowed>
    <Site>$site{site}</Site>
    <ConditionID>1000</ConditionID>
    <Quantity>1</Quantity>
    <StartPrice>199.0</StartPrice>
    <BuyItNowPrice currencyID="$site{currency}">2000.0</BuyItNowPrice>
    <ListingDuration>Days_3</ListingDuration>
    <ListingType>Chinese</ListingType>
    <DispatchTimeMax>3</DispatchTimeMax>
    <ShippingDetails>
      <ShippingType>Flat</ShippingType>
      <ShippingServiceOptions>
        <ShippingServicePriority>1</ShippingServicePriority>
        <ShippingService>USPSMedia</ShippingService>
        <ShippingServiceCost>2.50</ShippingServiceCost>
      </ShippingServiceOptions>
    </ShippingDetails>
    <ReturnPolicy>
      <ReturnsAcceptedOption>ReturnsAccepted</ReturnsAcceptedOption>
      <RefundOption>MoneyBack</RefundOption>
      <ReturnsWithinOption>Days_30</ReturnsWithinOption>
      <Description>If you are not satisfied, return the book for refund.</Description>
      <ShippingCostPaidByOption>Buyer</ShippingCostPaidByOption>
    </ReturnPolicy>
    <Country>$site{country}</Country>
    <Currency>$site{currency}</Currency>
    <PostalCode>$site{zip}</PostalCode>
    <PaymentMethods>PayPal</PaymentMethods>
    <PayPalEmailAddress>$paypalEmail</PayPalEmailAddress>
    <PictureDetails>
      <PictureURL>http://thumbs.ebaystatic.com/pict/41007087008080_0.jpg</PictureURL>
    </PictureDetails>
  </Item>
</AddItemRequest>
XML

   return requestAndParse( $header, $xml );
}


sub GetMyeBaySelling { # http://developer.ebay.com/devzone/xml/docs/Reference/eBay/GetMyeBaySelling.html
   my $developer = shift;
   my $token = $developers{$developer}{token};
   my $header = getHeader( $developer, 'GetMyeBaySelling' );
   my $xml =<<XML;
<?xml version="1.0" encoding="UTF-8"?>
<GetMyeBaySellingRequest xmlns="urn:ebay:apis:eBLBaseComponents">
   <RequesterCredentials>
      <eBayAuthToken>$token</eBayAuthToken>
   </RequesterCredentials>
   <Version>551</Version>
   <SoldList>
      <DurationInDays>8</DurationInDays>
      <IncludeNotes>false</IncludeNotes>
      <Pagination>
         <EntriesPerPage>200</EntriesPerPage>
         <PageNumber>1</PageNumber>
      </Pagination>
    <Sort>ItemID</Sort>
  </SoldList>
</GetMyeBaySellingRequest>
XML

   return requestAndParse( $header, $xml );
}


1;

