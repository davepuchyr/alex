#!/usr/bin/perl -w
# $Id: torpolipo.pl 96 2010-03-16 10:17:19Z dave $

use strict;
use open qw(:std :utf8);

usage() if ( scalar( @ARGV ) != 2 || $ARGV[1] !~ m|^\d+$| || $ARGV[1] < 9052 || $ARGV[1] % 2 );

my ( $ExitNode, $SocksPort ) = @ARGV;
my $confTor = doTor( $ExitNode, $SocksPort );
my $confPolipo = doPolipo( $ExitNode, $SocksPort );

my $tor = "sudo -u _tor nice tor -f $confTor";
print "$tor\n";
print `$tor` or die "tor doesn't like $confTor: $?";

my $polipo = "nice polipo -c $confPolipo";
print "$polipo\n";
print `sudo -u polipo $polipo` or die "polipo doesn't like $confPolipo: $?";

exit( 0 );


sub killByPort {
   my $port = shift;
   foreach my $line ( split( /\n/,  `netstat -nlp --protocol=inet --tcp` ) ) {
      next if ( $line !~ m|:$port| );
      my ( $pid ) = $line =~ m|(\d+)/|;
      `kill -s SIGTERM $pid` and die "couldn't kill pid $pid";
      return !print "killed $pid\n";
   }
}


sub writeFile {
   my ( $file, $content ) = @_;
   open( OUT, '>:utf8', $file ) or die "couldn't open $file: $!\n"; # HARD-CODED
   print OUT $content;
   close( OUT ) or die "couldn't close $file: $!\n";
   return $file;
}


sub doTor {
   my ( $ExitNode, $SocksPort ) = @_;
   my $ControlPort = 1 + $SocksPort; # HARD-CODED
   my $DataDirectory = "/var/lib/tor.$ExitNode"; # HARD-CODED
   my $conf =<<EOS;
# written by $0 @ARGV
#ExcludeNodes TODO: have perl query a directory server, find slow/distant nodes, and include them here
#AllowSingleHopCircuits 1
#AllowSingleHopExits 1
AvoidDiskWrites 1
#BandwidthBurst 512 KB
#BandwidthRate 256 KB
ClientOnly 1
ControlListenAddress 127.0.0.1:$ControlPort
ControlPort $ControlPort
CookieAuthentication 1
DataDirectory $DataDirectory
EnforceDistinctSubnets 0
#ExcludeSingleHopRelays 0
ExitNodes $ExitNode
FascistFirewall 0
Log notice file /var/log/tor/tor.$ExitNode.log
#LongLivedPorts 80, 443
MaxAdvertisedBandwidth 0 KB
#MaxCircuitDirtiness 999999
#NewCircuitPeriod 999999
NumEntryGuards 1
PidFile /var/run/tor/tor.$ExitNode.pid
RunAsDaemon 1
SafeLogging 0
SocksPort $SocksPort
StrictExitNodes 1
#User _tor

DirAllowPrivateAddresses 1
DirServer 127.0.0.1:9030 4D99D64D232889CB804E33EF2DA267511B2BF8A5
#StrictEntryNodes 1
#EntryNodes \$A2A4C3686F24B417D99B8464DE23FBFF56BFA8BD
FastFirstHopPK 1
MaxOnionsPending 0
__DisablePredictedCircuits 1
__ReloadTorrcOnSIGHUP 1
EOS

   mkdir( $DataDirectory ) if ( !-d $DataDirectory );
   `chown -R _tor._tor $DataDirectory && chmod 700 $DataDirectory` if ( !-o int( `id -u _tor` ) );
   killByPort( $SocksPort );
   return writeFile( "/etc/tor/torrc.$ExitNode", $conf ); # HARD-CODED
}


sub doPolipo {
   my ( $ExitNode, $SocksPort ) = @_;
   my $proxyPort = int( 8118 + ( $SocksPort - 9050 ) / 2 ); # HARD-CODED; proxyPort starts at 8119 since SocksPort starts at 9051
   my $logfile = '/var/log/polipo'; # HARD-CODED
   my $conf =<<EOS;
# written by $0 @ARGV
allowedClients = "0.0.0.0/0"
allowedPorts = 1-65535
cacheIsShared = false
censoredHeaders = from,accept-language,x-pad,link
censorReferer = maybe
chunkHighMark = 33554432
daemonise = true
#disableConfiguration = true
#disableLocalInterface = true
disableVia = true
diskCacheRoot = ""
dnsUseGethostbyname = yes
localDocumentRoot = ""
logFile = $logfile
maxConnectionAge = 5m
maxConnectionRequests = 120
proxyAddress = "0.0.0.0"
proxyName = "localhost"
proxyPort = $proxyPort
serverMaxSlots = 8
serverSlots = 2
socksParentProxy = "localhost:$SocksPort"
socksProxyType = socks5
tunnelAllowedPorts = 1-65535
EOS

  `chgrp polipo $logfile && chmod g+rw $logfile` if ( !-W int( `id -u polipo` ) );
   killByPort( $proxyPort );
   return writeFile( "/etc/polipo/polipo.$ExitNode", $conf ); # HARD-CODED
}


sub usage {
   exit !print <<EOS;
usage: $0 aSingleStrictExitNode theTorSocksPort

where theTorSocksPort is >= 9052 and even.

$0 launchs tor with StrictExitNode aSingleStrictExitNode listening on
SocksPort with ControlPort == SocksPort + 1, and polipo with
socksParentProxy == SocksPort and proxyPort == 8118 + ( SocksPort - 9050 ) / 2.
ie, it is assumed that the stock tor and polipo in initscripts bind to ports
9050 (possibly 9051) and 8118, respectively, so we follow them.
EOS
}

