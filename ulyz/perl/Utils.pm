package Utils;
# $Id: Utils.pm 94 2010-03-03 13:01:54Z dave $

use Cwd;
use DBI;
use Time::Local;
use XML::Twig;


sub getDBH {
   my $href = shift;
   my $drh = DBI->install_driver( 'mysql' );
   my $dsn = "DBI:mysql:database=$ENV{DB_ULYZ_EBAY};host=$ENV{DB_ULYZ_HOST};port=$ENV{DB_ULYZ_PORT}";

   $href = () if ( !defined( $href ) );
   $href->{mysql_enable_utf8} = 1 if ( !exists( $href->{mysql_enable_utf8} ) );
   $href->{InactiveDestroy} = 1 if ( !exists( $href->{InactiveDestroy} ) ); # disable auto desctruct of the handle on DESTROY
   $href->{RowCacheSize} = 1 if ( !exists( $href->{RowCacheSize} ) ); # disable row cache

   return DBI->connect( $dsn, $ENV{DB_ULYZ_USER}, $ENV{DB_ULYZ_PASSWORD}, $href ) or die "$DBI::errstr\n";
}


sub toUnixTime {
   my $date = shift;
   my ( $yyyy, $mm, $dd, $hour, $min, $sec ) = $date =~ m|(\d\d\d\d).(\d\d).(\d\d).(\d\d).(\d\d).(\d\d)|o;
   return timegm( $sec, $min, $hour, $dd, $mm - 1, $yyyy );
}


sub prettyPrintXML {
   my $node = shift;
   my $twig = XML::Twig->new( pretty_print => 'indented' );
   $twig->parse( $node->toString() );
   $twig->print();
}


sub error {
   my $errstr = shift;
   print( "*** $errstr ***\n" );
}


sub pwd {
   my ( $pwd ) = Cwd::realpath( $0 ) =~ m|(.*/)|;
   return $pwd;
}


sub shuffle {
   my $array = shift;
   my $i = scalar( @$array );
   while ( --$i > 0 ) {
      my $j = int( rand( $i + 1 ) );
      next if $i == $j;
      @$array[ $i, $j] = @$array[$j, $i];
   }
}


sub updateActiveBids {
   my ( $line, $account ) = @_;
   my ( $active ) = $line =~ m|MY_EBAY_ACTIVE_BIDS.*(\d+)| if ( $line =~ m|MY_EBAY_ACTIVE_BIDS| ); # HARD-CODED in conjunction with MyEbay.js

   return if ( !defined( $active ) );

   my $i = 0;
   my %months = map { $_, sprintf( '%02d', ++$i ); } qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
   my ( $mon, $day, $year, $hh, $mm, $ss, $offset ) = $line =~ m|...(...) (\d{2}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT(.\d{2})|;
   $hh += -1 * $offset; # NOTE: no minute adjustment, which would cause breakage in Newfoundland
   $mon = $months{$mon};

   my $sql =<<EOSQL;
   SELECT command FROM events
   WHERE at >= '$year-$mon-$day $hh:$mm:$ss'
   AND command LIKE '%$account%'
   AND command LIKE '%$ENV{CMD_KEY_BID_STRATEGY}%'
EOSQL
   print $sql;
   my $dbh = Utils::getDBH();
   my $sth = $dbh->prepare( $sql ) or die "couldn't prepare: $dbh->errstr\n";

   $sth->execute() or die "couldn't execute: $sth->errstr\n";

   my $futures = 0;
   while ( my ( $command ) = $sth->fetchrow_array() ) {
      my %command = %{+ JSON::XS->new->utf8->decode( $command ) };
      ++$futures if ( grep( /$command{$ENV{CMD_KEY_BID_STRATEGY}}/, $ENV{BIDDER_BID_STRATEGIES_INITIAL} ) );
   }

   $sth->finish() or die "couldn't finish: $sth->errstr\n";

   $sql =<<EOSQL;
   UPDATE accounts SET
   active = ( $active + $futures ),
   active_updated = NOW()
   WHERE account = '$account';
EOSQL
   print $sql;
   $dbh->do( $sql ) or die "couldn't finish: $dbh->errstr\n";
   $dbh->disconnect() or die "couldn't disconnect: $!\n";
   $dbh = undef;
}

1;

