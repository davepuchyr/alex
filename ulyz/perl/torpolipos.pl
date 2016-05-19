#!/usr/bin/perl -w
# $Id: torpolipos.pl 96 2010-03-16 10:17:19Z dave $
# check node status at https://torstat.xenobite.eu/index.php?SortBy=G

use strict;
use Cwd qw|abs_path|;

$| = 1;

my $nap = 'sleep 15'; # HARD-CODED
my ( $wd ) = abs_path($0) =~ m|(.*)/|;
my $torpolipo = "$wd/torpolipo.pl"; # HARD-CODED

# NEVER start with anything other than 9052 and ALWAYS increment by 2
print `$torpolipo earthling           9052; $nap` or die $!; # AT
print `$torpolipo svrmarty            9054; $nap` or die $!; # AT
# flaky as of 2010.02.17 print `$torpolipo robotica1337        9056; $nap` or die $!; # BG
print `$torpolipo SoftPower           9056; $nap` or die $!; # US: 198.202.25.251 as of 2010.02.17
print `$torpolipo podgornycz          9058; $nap` or die $!; # CZ
print `$torpolipo RedempTOR           9060; $nap` or die $!; # CZ
print `$torpolipo bach                9062; $nap` or die $!; # DE
# flaky as of 2010.02.17 print `$torpolipo charon              9064; $nap` or die $!; # DE; was on ded1
print `$torpolipo theagricolasTOR     9064; $nap` or die $!; # US: 75.69.69.197 as of 2010.02.17
print `$torpolipo darkworldsolutions  9066; $nap` or die $!; # DE
print `$torpolipo digineo1            9068; $nap` or die $!; # DE
print `$torpolipo FoeBuD3             9070; $nap` or die $!; # DE
print `$torpolipo gpfTOR2             9072; $nap` or die $!; # DE
print `$torpolipo hanfisTorRelay      9074; $nap` or die $!; # DE; was on jazztel
print `$torpolipo kallisti            9076; $nap` or die $!; # DE
print `$torpolipo s15321456           9078; $nap` or die $!; # DE
print `$torpolipo tamaribuchi2        9080; $nap` or die $!; # DE
print `$torpolipo gigatux             9082; $nap` or die $!; # GB; was on dual
print `$torpolipo fissefjaes          9084; $nap` or die $!; # DK
print `$torpolipo Tatooine            9086; $nap` or die $!; # ES
# flaky as of 2010.02.17 print `$torpolipo Finntaur            9088; $nap` or die $!; # FI
print `$torpolipo 703server           9088; $nap` or die $!; # US: 173.62.201.193 as of 2010.02.17
print `$torpolipo colinwillsdorkyahoo 9090; $nap` or die $!; # GB; was on dfw
print `$torpolipo pboxlevel3          9092; $nap` or die $!; # IT
print `$torpolipo sullust             9094; $nap` or die $!; # IT
print `$torpolipo upcensors           9096; $nap` or die $!; # LU
print `$torpolipo AMORPHIS            9098; $nap` or die $!; # NL; was on ded
print `$torpolipo 1000rpmLinux        9100; $nap` or die $!; # SE
print `$torpolipo TorStockholm        9102; $nap` or die $!; # SE
print `$torpolipo vallentunangserver  9104; $nap` or die $!; # SE
print `$torpolipo MrBottleServer      9106; $nap` or die $!; # DE
print `$torpolipo brazoslink          9108; $nap` or die $!; # US: 69.39.49.199 as of 2010.02.17
print `$torpolipo desync              9110; $nap` or die $!; # US: 66.230.230.230 as of 2010.02.17
print `$torpolipo evoLution           9112; $nap` or die $!; # US: 70.114.140.223 as of 2010.02.17
print `$torpolipo kgabertgoldmine2    9114; $nap` or die $!; # US: 166.70.99.91 as of 2010.02.17
print `$torpolipo muffinman           9116; $nap` or die $!; # US: 18.246.2.88 as of 2010.02.17
print `$torpolipo omgprivacy          9118; $nap` or die $!; # US: 99.168.109.197 as of 2010.02.17
print `$torpolipo RPOGX4403           9120; $nap` or die $!; # US: 173.23.71.206 as of 2010.02.17
print `$torpolipo trithnt             9122; $nap` or die $!; # US: 208.75.91.19 as of 2010.02.17

