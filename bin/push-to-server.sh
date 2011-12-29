#!/bin/bash
# Distributed under the terms of the BSD License.
# Copyright (c) 2011 Phil Cryer afanousergio@gmail.com
# Source https://github.com/philcryer/lipsync
##
# Usage 
# push-to-server.sh <local dir> <remote server:remote port/remote dir>


PARAM_CONF_FILE=/opt/helenasync/conf/helenasync.conf

###############
# source config, define logfile
###############
if [ -e $PARAM_CONF_FILE ]; then
        . $PARAM_CONF_FILE
else
	echo "****** ERROR ******* : The configuration file $PARAM_CONF_FILE does not exist !"
fi

###############
# Print configuration file (just in case we are in command line mode)
###############
cat $CONF_FILE

###############
# Test if variable $1, $2 and $3 are set or not
###############

# Local dir
if [ -n "$1" ]; then
	echo "Variable 1 is set"
	LOCAL_DIR="$1"
else
	echo "Variable 1 LOCAL_DIR is not set"
	echo "Local dir : "
	read LOCAL_DIR
fi

# Remote dir
if [ -n "$2" ]; then
	echo "Variable 2 is set"
	REMOTE_DIR="$2"
else
	echo "Variable 2 REMOTE_DIR is not set"
	echo "Remote dir : "
	read REMOTE_DIR
fi

#REMOTE_DIR="$2"
RSYNC_OPTS="-ravC --stats"
POPUPMESSAGE=""
SLEEP_DURATION=5

###############
# prevent data loss if there is a running rsync launched by lsyncd
###############
echo "`date "+%a %b %d %T %Y"` Cron: checking for running lipsync processes" >> $LOGFILE
eval NB_RSYNC_PROCESS=`ps aux | grep rsync | grep "$REMOTE_HOST" | grep -v rsyncssh | grep -cv grep`
echo "`date "+%a %b %d %T %Y"` Cron: found $NB_RSYNC_PROCESS running $NAME processes" >> $LOGFILE
if [ $NB_RSYNC_PROCESS -ne 0 ]; then
        EXITMSG="`date "+%a %b %d %T %Y"` Cron: not running $NAME, another process already running"
        echo "${EXITMSG}" >> $LOGFILE
        $NOTIFY_BIN "${EXITMSG}"
        exit 0
fi

echo "-------- Retrieving updates : $REMOTE_DIR -> $LOCAL_DIR" >> $LOGFILE

nice rsync $RSYNC_OPTS --stats --delete --log-file=$LOGFILE --exclude-from=$EXCLUDE_FILE  -e "ssh -l $REMOTE_USER_NAME -p 22" $LOCAL_DIR $REMOTE_DIR 

echo "-------- Done" >> $LOGFILE
###

###############
# this writes source -> destination details to log
###############
eval LOCAL_HOST=`hostname`
echo "`date "+%a %b %d %T %Y"` Cron: updated $REMOTE_HOST -> $LOCAL_HOST" >> $LOGFILE || true

###############
# get line number of last run
###############
LAST_RUN=`cat $LOGFILE | grep --line-number  "] receiving file list" | tail -n1 | cut -d':' -f1`

###############
# count deleted files since LAST_RUN
###############
DELETED_FILES=`cat $LOGFILE | sed -n ''$LAST_RUN'$p' | grep "*deleting "| wc -l`

###############
# popup if we've had deleted files on this run
###############
if [ "${DELETED_FILES}" -ne '0' ]; then
    	if [ "${DELETED_FILES}" -eq '1' ]; then
		    POPUPMESSAGE="${POPUPMESSAGE} $DELETED_FILES file deleted"
	    else
            POPUPMESSAGE="${POPUPMESSAGE} $DELETED_FILES files deleted"
        fi
else
        #POPUPMESSAGE=`echo "${DELETED_FILES} were deleted"`
        POPUPMESSAGE="No file was deleted"
fi

###############
# count transfered files
###############
TOTAL_TRANS=`cat $LOGFILE |grep "Number of files transferred" | tail -n1 | cut -d" " -f8`

if [ "${TOTAL_TRANS}" -gt '0' ]; then
    	if [ "${TOTAL_TRANS}" -eq '1' ]; then
		    POPUPMESSAGE="${POPUPMESSAGE} \n$TOTAL_TRANS file synced"
	    else
            POPUPMESSAGE="${POPUPMESSAGE} \n$TOTAL_TRANS files synced"
        fi
else
        #POPUPMESSAGE=`echo "${POPUPMESSAGE}\n${TOTAL_TRANS} were transferred"`
        POPUPMESSAGE="${POPUPMESSAGE}\nNo file was transferred"
fi

###############
# pop up info
###############
$NOTIFY_BIN "$LOCAL_DIR \n${POPUPMESSAGE}"

###############
# Wait few seconds
###############
echo "Waiting $SLEEP_DURATION seconds ..." >> $LOGFILE
sleep $SLEEP_DURATION
echo "Woke up !"  >> $LOGFILE
