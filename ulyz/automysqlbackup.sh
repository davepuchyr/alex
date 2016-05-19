#!/bin/bash
# $Id: automysqlbackup.sh 107 2010-07-28 08:49:25Z dave $
#
# MySQL Backup Script
# VER. 1.2 - http://members.lycos.co.uk/wipe_out/automysqlbackup
# Copyright (c) 2002-2003 wipe_out@lycos.co.uk
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#=====================================================================
#=====================================================================
# Set the following 7 variables to your system needs
#=====================================================================
#=====================================================================

# Username to access the MySQL server e.g. dbuser
USERNAME=dave

# Username to access the MySQL server e.g. password
PASSWORD=$DB_ULYZ_PASSWORD

# Host name (or IP address) of MySQL server e.g "localhost"
DBHOST=localhost

# List of DBNAMES for Daily/Weekly Backup e.g. "DB1 DB2 DB3"
DBNAMES=ebay

# List of DBBNAMES for Monthly Backups (see Doc's below)
MDBNAMES="$DBNAMES"

# Backup directory location e.g /backups
BACKUPDIR=~/backups

# Separate backup directory and file for each DB? (yes or no)
SEPDIR=yes

# Mail backup log? (yes or no)
MAILLOG=yes

# Email Address to send log to? (user@domain.com)
MAILADDR=dave

#=====================================================================
# Setup Instructions
#=====================================================================
# Set USERNAME and PASSWORD of a user that has SELECT permission to
# ALL databases.
#
# Set the DBHOST option to the server you wish to backup, leave the
# default to backup "this server".(to backup multiple servers make
# copies of this file and set the options for that server)
#
# Put in the list of DBNAMES(Databases)to be backed up.
#
# Put in the list of MDBNAMES(Databases)to be backed up. You should
# always include "mysql" in this list to backup your user/password
# information allong with any other# DB's that you only feel need to
# be backed up monthly. (if using a hosted server then you should
# probably remove "mysql" as your provider will be backing this up)
#
# You can change /backups to anything you like but be sure to change
# the BACKUPDIR setting above..
#
# The SEPDIR option allows you to choose to have all DB's backed up to
# a single file (fast restore of entire server in case of crash) or to
# seperate directories for each DB (each DB can be restored seperately
# in case of single DB corruption).
#
# The MAILLOG and MAILADDR options and pretty self explanitory, use
# these to have the backup log mailed to you at any email address.
# (this will require that you are permitted to run the "mail" program
# on your server.)
#
# Finally copy automysqlbackup.sh to anywhere on your server and make sure
# to set executable permission. You can also copy the script to
# /etc/cron.daily to have it execute automatically every night or simply
# place a symlink in /etc/cron.daily to the file if you wish to keep it 
# somwhere else.(On Debian copy the file with no extention for it to be run
# by cron e.g just name the file "automysqlbackup")
#
# Thats it..
#
#=====================================================================
# Backup Rotation..
#=====================================================================
#
# Daily Backups are rotated weekly..
# Weekly Backups are run on Saturday Morning when
# cron.daily scripts are run...
# Weekly Backups are rotated on a 5 week cycle..
# Monthly Backups are run on the 1st of the month..
# Monthly Backups are NOT rotated automatically...
# It may be a good idea to copy Monthly backups offline or to another
# computer.
#
#=====================================================================
# Please Note!!
#=====================================================================
#
# I take no resposibility for any data loss or corruption when using
# this script..
# This script will not help in the event of a hard drive crash. If a 
# copy of the backup has not be stored offline or on another PC..
# You should copy your backups offline regularly for best protection.
#
# Happy backing up...
#
#=====================================================================
# Change Log
#=====================================================================
#
# VER 1.2 - (2003-03-16)
#   Added server name to the backup log so logs from multiple servers
#   can be easily identified.
# VER 1.1 - (2003-03-13)
#   Small Bug fix in monthly report. (Thanks Stoyanski)
#   Added option to email log to any email address. (Inspired by Stoyanski)
#   Changed Standard file name to .sh extention.
#   Option are set using yes and no rather than 1 or 0.
# VER 1.0 - (2003-01-30)
#   Added the ability to have all databases backup to a single dump
#   file or seperate directory and file for each database.
#   Output is better for log keeping.
# VER 0.6 - (2003-01-22)
#   Bug fix for daily directory (Added in VER 0.5) rotation.
# VER 0.5 - (2003-01-20)
#   Added "daily" directory for daily backups for neatness (suggestion by Jason)
#   Added DBHOST option to allow backing up a remote server (Suggestion by Jason)
#   Added "--quote-names" option to mysqldump command.
#   Bug fix for handling the last and first of the year week rotation.
# VER 0.4 - (2002-11-06)
#   Added the abaility for the script to create its own directory structure.
# VER 0.3 - (2002-10-01)
#   Changed Naming of Weekly backups so they will show in order.
# VER 0.2 - (2002-09-27)
#   Corrected weekly rotation logic to handle weeks 0 - 10 
# VER 0.1 - (2002-09-21)
#   Initial Release
#
#=====================================================================
#=====================================================================
#=====================================================================
# Should not need to be modified from here down!!
#=====================================================================
#=====================================================================
#=====================================================================
PATH=/usr/local/bin:/usr/bin:/bin
DATE=`date +%Y-%m-%d`			# Datestamp e.g 2002-09-21
DOW=`date +%A`				# Day of the week e.g. Monday
DOM=`date +%d`				# Date of the Month e.g. 27
M=`date +%B`				# Month e.g January
W=`date +%V`				# Week Number e.g 37
VER=1.2					# Version Number
LOGFILE=/sqlbackup.log			# Logfile Name

# Create required directories
if [ ! -e "$BACKUPDIR" ]		# Check Backup Directory exists.
	then
	mkdir $BACKUPDIR
fi

if [ ! -e "$BACKUPDIR/daily" ]		# Check Daily Directory exists.
	then
	mkdir $BACKUPDIR/daily
fi

if [ ! -e "$BACKUPDIR/weekly" ]		# Check Weekly Directory exists.
	then
	mkdir $BACKUPDIR/weekly
fi

if [ ! -e "$BACKUPDIR/monthly" ]	# Check Monthly Directory exists.
	then
	mkdir $BACKUPDIR/monthly
fi

# Hostname for LOG information
if [ "$DBHOST" = "localhost" ]; then
	HOST=`hostname`
else
	HOST=$DBHOST
fi	

echo ======================================================================>>$BACKUPDIR/$LOGFILE
echo AutoMySQLBackup VER $VER>>$BACKUPDIR/$LOGFILE
echo >>$BACKUPDIR/$LOGFILE
echo Backup of Database Server - $HOST>>$BACKUPDIR/$LOGFILE
echo >>$BACKUPDIR/$LOGFILE
echo ======================================================================>>$BACKUPDIR/$LOGFILE

# Test is seperate DB backups are required
if [ "$SEPDIR" = "yes" ]; then
echo Backup Start `date`>>$BACKUPDIR/$LOGFILE
echo ======================================================================>>$BACKUPDIR/$LOGFILE
	# Monthly Full Backup of all Databases
	if [ $DOM = "01" ]; then
		for MDB in $MDBNAMES
		do
			if [ ! -e "$BACKUPDIR/monthly/$MDB" ]		# Check Monthly DB Directory exists.
			then
				mkdir $BACKUPDIR/monthly/$MDB
			fi
			echo Monthly Backup of $MDB...>>$BACKUPDIR/$LOGFILE
				mysqldump --user=$USERNAME --password=$PASSWORD --host=$DBHOST --quote-names --opt --databases $MDB > $BACKUPDIR/monthly/$MDB/$DATE.$M.$MDB.sql
				gzip -f $BACKUPDIR/monthly/$MDB/$DATE.$M.$MDB.sql
			echo>>$BACKUPDIR/$LOGFILE
			echo Backup Information for $BACKUPDIR/monthly/$MDB/$DATE.$M.$MDB.sql.gz>>$BACKUPDIR/$LOGFILE
				gzip -l $BACKUPDIR/monthly/$MDB/$DATE.$M.$MDB.sql.gz>>$BACKUPDIR/$LOGFILE
			echo ---------------------------------------------------------------------->>$BACKUPDIR/$LOGFILE
		done
	fi

	for DB in $DBNAMES
	do
	# Create Seperate directory for each DB
	if [ ! -e "$BACKUPDIR/daily/$DB" ]		# Check Daily DB Directory exists.
		then
		mkdir $BACKUPDIR/daily/$DB
	fi
	
	if [ ! -e "$BACKUPDIR/weekly/$DB" ]		# Check Weekly DB Directory exists.
		then
		mkdir $BACKUPDIR/weekly/$DB
	fi
	
	# Weekly Backup
	if [ $DOW = "Saturday" ]; then
		echo Weekly Backup of Database \( $DB \)>>$BACKUPDIR/$LOGFILE
		echo Rotating 5 weeks Backups...>>$BACKUPDIR/$LOGFILE
			if [ "$W" -le 05 ];then
				REMW=`expr 48 + $W`
			elif [ "$W" -lt 15 ];then
				REMW=0`expr $W - 5`
			else
				REMW=`expr $W - 5`
			fi
		rm -fv $BACKUPDIR/weekly/$DB/week.$REMW.*>>$BACKUPDIR/$LOGFILE
		echo>>$BACKUPDIR/$LOGFILE
			mysqldump --user=$USERNAME --password=$PASSWORD --host=$DBHOST --quote-names --opt --databases $DB > $BACKUPDIR/weekly/$DB/week.$W.$DATE.sql
			gzip -f $BACKUPDIR/weekly/$DB/week.$W.$DATE.sql
	
		echo Backup Information for $BACKUPDIR/weekly/$DB/week.$W.$DATE.sql.gz>>$BACKUPDIR/$LOGFILE
			gzip -l $BACKUPDIR/weekly/$DB/week.$W.$DATE.sql.gz>>$BACKUPDIR/$LOGFILE
		echo ---------------------------------------------------------------------->>$BACKUPDIR/$LOGFILE
	
	# Daily Backup
	else
		echo Daily Backup of Database \( $DB \)>>$BACKUPDIR/$LOGFILE
		echo Rotating last weeks Backup...>>$BACKUPDIR/$LOGFILE
			rm -fv $BACKUPDIR/daily/$DB/*.$DOW.sql.gz>>$BACKUPDIR/$LOGFILE
		echo>>$BACKUPDIR/$LOGFILE
			mysqldump --user=$USERNAME --password=$PASSWORD --host=$DBHOST --quote-names --opt --databases $DB > $BACKUPDIR/daily/$DB/$DATE.$DOW.sql
			gzip -f $BACKUPDIR/daily/$DB/$DATE.$DOW.sql
		
		echo Backup Information for $BACKUPDIR/daily/$DB/$DATE.$DOW.sql.gz>>$BACKUPDIR/$LOGFILE
			gzip -l $BACKUPDIR/daily/$DB/$DATE.$DOW.sql.gz>>$BACKUPDIR/$LOGFILE
		echo ---------------------------------------------------------------------->>$BACKUPDIR/$LOGFILE
	fi
	done
echo Backup End `date`>>$BACKUPDIR/$LOGFILE
echo ======================================================================>>$BACKUPDIR/$LOGFILE

else # One backup file for all DB's
echo Backup Start `date`>>$BACKUPDIR/$LOGFILE
echo ======================================================================>>$BACKUPDIR/$LOGFILE
	# Monthly Full Backup of all Databases
	if [ $DOM = "01" ]; then
		echo Monthly full Backup of \( $MDBNAMES \)...>>$BACKUPDIR/$LOGFILE
			mysqldump --user=$USERNAME --password=$PASSWORD --host=$DBHOST --quote-names --opt --databases $MDBNAMES > $BACKUPDIR/monthly/$DATE.$M.all-databases.sql
			gzip -f $BACKUPDIR/monthly/$DATE.$M.all-databases.sql
		echo>>$BACKUPDIR/$LOGFILE
		echo Backup Information for $BACKUPDIR/monthly/$DATE.$M.all-databases.sql.gz>>$BACKUPDIR/$LOGFILE
			gzip -l $BACKUPDIR/monthly/$DATE.$M.all-databases.sql.gz>>$BACKUPDIR/$LOGFILE
		echo ---------------------------------------------------------------------->>$BACKUPDIR/$LOGFILE
	fi

	# Weekly Backup
	if [ $DOW = "Saturday" ]; then
		echo Weekly Backup of Databases \( $DBNAMES \)>>$BACKUPDIR/$LOGFILE
		echo>>$BACKUPDIR/$LOGFILE
		echo Rotating 5 weeks Backups...>>$BACKUPDIR/$LOGFILE
			if [ "$W" -le 05 ];then
				REMW=`expr 48 + $W`
			elif [ "$W" -lt 15 ];then
				REMW=0`expr $W - 5`
			else
				REMW=`expr $W - 5`
			fi
		rm -fv $BACKUPDIR/weekly/week.$REMW.*>>$BACKUPDIR/$LOGFILE
		echo>>$BACKUPDIR/$LOGFILE
			mysqldump --user=$USERNAME --password=$PASSWORD --host=$DBHOST --quote-names --opt --databases $DBNAMES > $BACKUPDIR/weekly/week.$W.$DATE.sql
			gzip -f $BACKUPDIR/weekly/week.$W.$DATE.sql
		
		echo Backup Information for $BACKUPDIR/weekly/week.$W.$DATE.sql.gz>>$BACKUPDIR/$LOGFILE
			gzip -l $BACKUPDIR/weekly/week.$W.$DATE.sql.gz>>$BACKUPDIR/$LOGFILE
		echo ---------------------------------------------------------------------->>$BACKUPDIR/$LOGFILE
		
	# Daily Backup
	else
		echo Daily Backup of Databases \( $DBNAMES \)>>$BACKUPDIR/$LOGFILE
		echo>>$BACKUPDIR/$LOGFILE
		echo Rotating last weeks Backup...>>$BACKUPDIR/$LOGFILE
			rm -fv $BACKUPDIR/daily/*.$DOW.sql.gz>>$BACKUPDIR/$LOGFILE
		echo>>$BACKUPDIR/$LOGFILE
			mysqldump --user=$USERNAME --password=$PASSWORD --host=$DBHOST --quote-names --opt --databases $DBNAMES > $BACKUPDIR/daily/$DATE.$DOW.sql
			gzip -f $BACKUPDIR/daily/$DATE.$DOW.sql
		echo Backup Information for $BACKUPDIR/daily/$DATE.$DOW.sql.gz>>$BACKUPDIR/$LOGFILE
			gzip -l $BACKUPDIR/daily/$DATE.$DOW.sql.gz>>$BACKUPDIR/$LOGFILE
		echo ---------------------------------------------------------------------->>$BACKUPDIR/$LOGFILE
	fi
echo Backup End `date`>>$BACKUPDIR/$LOGFILE
echo ======================================================================>>$BACKUPDIR/$LOGFILE
fi

if [ "$MAILLOG" = "yes" ]
then
	cat $BACKUPDIR/$LOGFILE | mail -s "MySQL Backup Log for $HOST - $DATE" $MAILADDR
else
	cat $BACKUPDIR/$LOGFILE
fi

# Clean up Logfile
rm -f $BACKUPDIR/$LOGFILE

exit 0
