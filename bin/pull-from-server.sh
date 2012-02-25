#!/bin/bash
# Distributed under the terms of the BSD License.
# Copyright (c) 2011 Phil Cryer phil.cryer@gmail.com
# Source https://github.com/philcryer/lipsync

PARAM_CONF_FILE=/opt/helenasync/conf/helenasync.conf

###############
# source config, define logfile
###############
if [ -e $PARAM_CONF_FILE ]; then
        . $PARAM_CONF_FILE
else
	echo "****** ERROR ******* : The configuration file $PARAM_CONF_FILE does not exist !"
fi

POPUPMESSAGE=""
SLEEP_DURATION=5


# Remote dir
if [ -n "$1" ]; then
	echo "Variable REMOTE_DIR is set"
	REMOTE_DIR="$1"
else
	echo "Variable REMOTE_DIR is not set. Exiting ..."
	exit -1
fi

# Local dir
if [ -n "$1" ]; then
	echo "Variable LOCAL_DIR is set"
	LOCAL_DIR="$2"
else
	echo "Variable LOCAL_DIR is not set. Exiting ..."
	exit -1
fi

# rsync options
if [ -n "$3" ]; then
	echo "Variable RSYNC_OPTS is set"
	RSYNC_OPTS="$3"
else
	echo "Variable RSYNC_OPTS is not set. Setting default value ..."
	RSYNC_OPTS="-ravC --stats"
fi

###############
# DO NOT RUN if lipsyncd isn't running
###############
eval LIPSYNCD_PROCESS=`ps aux | grep $PIDFILE | grep -cv grep`
if [ $LIPSYNCD_PROCESS -eq 0 ]; then
            echo "No $NAME process running. Exiting ..."
            $NOTIFY_BIN "No $NAME process running. Exiting ..."
	    exit 0
fi


###############
# prevent data loss if there is a running rsync launched by lsyncd
###############

# Extract remote host from remote dir path
CURRENT_REMOTE_HOST=$(echo $REMOTE_DIR  | cut -d: -f1)
echo "`date "+%a %b %d %T %Y"` Cron: checking for running lipsync processes" >> $LOGFILE
eval NB_RSYNC_PROCESS=`ps aux | grep rsync | grep "$CURRENT_REMOTE_HOST" | grep -v rsyncssh | grep -cv grep`
echo "`date "+%a %b %d %T %Y"` Cron: found $NB_RSYNC_PROCESS running $NAME processes" >> $LOGFILE
if [ $NB_RSYNC_PROCESS -ne 0 ]; then
        EXITMSG="`date "+%a %b %d %T %Y"` Cron: not running $NAME, another process already running"
        echo "${EXITMSG}" >> $LOGFILE
        $NOTIFY_BIN "${EXITMSG}"
        exit 0
fi

# Do not sync if there are offline files available in the offline directory
if [ -d $OFFLINE_DIR ]; then
	offlinefilesnb=`ls $OFFLINE_DIR | wc -l`
	if [ $offlinefilesnb -ne 0 ]; then
		echo "There is no offline file, continue execution" >> $LOGFILE
	else
		EXITMSG="There are $offlinefilesnb offline files. Please run load-offline-items script to push the offline files to upstream"
		echo $EXITMSG >> $LOGFILE
		$NOTIFY_BIN "Offline files exist" $EXITMSG
		exit 0
	fi
else
	echo "There is no $OFFLINE_DIR offline dir." >> $LOGFILE
fi

echo "-------- Retrieving updates : $REMOTE_DIR -> $LOCAL_DIR" >> $LOGFILE

nice rsync $RSYNC_OPTS --stats --delete --backup --backup-dir=$BACKUP_DIR --log-file=$LOGFILE --exclude-from=$EXCLUDE_FILE  -e "ssh -l $REMOTE_USER_NAME -p 22" $REMOTE_DIR $LOCAL_DIR

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
DELETED_FILES=`cat $LOGFILE | sed -n ''$LAST_RUN',$p' | grep "*deleting "| wc -l`

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
echo "Total trans : $TOTAL_TRANS"

if [ $TOTAL_TRANS -gt 0 ]; then
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

# do not popup if no file was deleted of synced
if [[ "${DELETED_FILES}" -eq "0" && "${TOTAL_TRANS}" -eq "0" ]]; then
	echo "Not poping up! ${POPUPMESSAGE}" >> $LOGFILE 
else
	$NOTIFY_BIN "$LOCAL_DIR \n${POPUPMESSAGE}"
fi


###############
# Wait few seconds
###############
echo "Waiting $SLEEP_DURATION seconds ..." >> $LOGFILE
sleep $SLEEP_DURATION
echo "Woke up !"  >> $LOGFILE
