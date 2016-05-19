#!/bin/bash
# $Id: ghost.sh 120 2010-10-10 17:47:05Z dave $

DEVELOPERS=$1 # $ENV{DEVELOPER_DELIMITER} delimited developers - no spaces!
AT=`date -u --date="now + $(($RANDOM % 59)) minutes + $(($RANDOM % 59)) seconds" +"%Y-%m-%d %H:%M:%S"`
NOW=`date -u`
EXE=`find $PWD -name ghost.pl` # HARD-CODED
WD=`dirname $EXE`
# JSON keys from ENV.pm
COMMAND=`cat <<EOS
{ "exe":"$EXE", "developers":"$DEVELOPERS", "email":"$USER", "wd":"$WD" }
EOS`
SQL=`cat <<EOS
INSERT INTO events ( at, command, log, modified ) VALUES ( '$AT', '$COMMAND', '[$NOW] inserted by $0\n', NOW() );
EOS`

echo $SQL

# db parameters from ENV.pm
cat <<EOSQL | mysql -u dave -p$DB_ULYZ_PASSWORD -h $DB_ULYZ_HOST $DB_ULYZ_EBAY
$SQL
EOSQL

