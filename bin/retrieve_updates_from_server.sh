#!/bin/sh -e
# Distributed under the terms of the BSD License.
# Copyright (c) 2011 Phil Cryer phil.cryer@gmail.com
# Source https://github.com/philcryer/lipsync

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
PARAM_CONF_FILE=/home/fullbright/.helenasync/helenasync.conf

###############
# source config, define logfile
###############
if [ -e $PARAM_CONF_FILE ]; then
        . $PARAM_CONF_FILE
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
# this from http://code.google.com/p/lsyncd/wiki/HowToExecAfter
# execute rsync just like it would have been done directly,
# but save the exit code
###############
IFS=
err=0

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

###############
# run the rsync command to check server for updated files
###############
#/usr/bin/rsync $@ || err=$?
#rsync -rav --stats --log-file=/home/$USER_NAME/.lipsyncd/lipsyncd.log -e "ssh -l $USER_NAME -p $SSH_PORT" --delete $REMOTE_HOST:$LOCAL_DIR $REMOTE_DIR
### Each rsync command must correspond to an entry in lsyncd config file
### to keep dirs sync two ways
###
echo "-------- RETRIEVING UPDATES FROM SERVER -------"
$PULL_BIN home.afanou.com:/media/DATA/SERGIO-PC/sergio/syncwin/ /home/fullbright/scripts/

$PULL_BIN home.afanou.com:/home/sergio/mydropbox/ /home/fullbright/mydropbox/

#$PULL_BIN home.afanou.com:/media/DATA/SERGIO-PC/sergio/documents/ /media/OS/Users/gpartner/Personnel/sergio/documents/
$PULL_BIN home.afanou.com:/media/DATA/SERGIO-PC/sergio/documents/ /home/fullbright/Documents/Personnel/documents/

#$PULL_BIN home.afanou.com:/media/DATA/SERGIO-PC/Professionel/ /media/OS/Users/gpartner/Professionel/
$PULL_BIN home.afanou.com:/media/DATA/SERGIO-PC/Professionel/ /home/fullbright/Documents/Professionnel/

echo "------------------ END ------------------------"
###

###############
# this writes source -> destination details to lipsyncd.log
###############
#eval LOCAL_HOST=`hostname`
#echo "`date "+%a %b %d %T %Y"` Cron: updated $REMOTE_HOST -> $LOCAL_HOST" >> $LOGFILE || true

###############
# get line number of last run
###############
#LAST_RUN=`cat $LOGFILE | grep --line-number  "] receiving file list" | tail -n1 | cut -d':' -f1`

###############
# count deleted files since LAST_RUN
###############
#DELETED_FILES=`cat $LOGFILE | sed -n ''$LAST_RUN',$p' | grep "*deleting "| wc -l`

###############
# popup if we've had deleted files on this run
###############
#echo "Notify  : $NOTIFY_BIN"
#if [ "${DELETED_FILES}" -ne '0' ]; then
#    	if [ "${DELETED_FILES}" -eq '1' ]; then
#		    $NOTIFY_BIN "$DELETED_FILES file deleted"
#	    else
#            $NOTIFY_BIN "$DELETED_FILES files deleted"
#        fi
#fi

###############
# count transfered files
###############
#TOTAL_TRANS=`cat $LOGFILE |grep "Number of files transferred" | tail -n1 | cut -d" " -f8`

#if [ "${TOTAL_TRANS}" -gt '0' ]; then
#    	if [ "${TOTAL_TRANS}" -eq '1' ]; then
#		    $NOTIFY_BIN "$TOTAL_TRANS file synced"
#	    else
#            $NOTIFY_BIN "$TOTAL_TRANS files synced"
#        fi
#fi

###############
# returns the exit code of rsync to lsyncd
###############
exit $err

