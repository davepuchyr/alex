#!/bin/bash

# accounts as of 2010.03.03
#ACCOUNTS='123mitraillette 1923claes am0379590alfons brihoma chrisfoord60 dansaw dosssantosj franart123 frassple glorydaysgone greg_rucq madebout nat_roby saga_hucorne saucin1730 svenmant tagness vargamdavid vic_trus zikuri'

ACCOUNTS='madebout 1923claes dosssantosj'

rm -f /tmp/searcher.*log
cd /home/alex/ulyz/perl
export DB_ULYZ_PASSWORD=xxxx
for account in $ACCOUNTS; do 
   nap=$(($RANDOM % 600));
   duration=$(($RANDOM % 200));
   echo "$account $nap $duration"
   ( touch /tmp/searcher.$account.log && sleep $nap && ./searcher.pl "{\"account\":\"$account\",\"duration\":$duration}" ) &
done

#( touch /tmp/searcher.saucin1730.log && sleep 376 && ./searcher.pl '{"account":"saucin1730","duration":201}' | tee /tmp/searcher.saucin1730.log ) &
tail -f /tmp/searcher.*log

