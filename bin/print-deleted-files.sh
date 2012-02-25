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
NTH_RUN=5
RESTORE=false

##############
# set the nth run
##############
if [ -n "$1" ]; then
	echo "Variable nth run is set"
	NTH_RUN="$1"
else
	echo "Variable nth run is not set. Keep default value: $NTH_RUN"
fi

###############
# get line number of last run
###############
LAST_RUN=`cat $LOGFILE | grep --line-number "] receiving file list" | tail -n$NTH_RUN | cut -d":" -f1 | sed -n 1p`
echo "Last run : $LAST_RUN"

###############
# count deleted files since LAST_RUN
###############
DELETED_FILES_NAMES=`cat $LOGFILE | sed -n ''$LAST_RUN',$p' | grep "*deleting " | cut -d'*' -f2 | sed -e 's/deleting   //'`
DELETED_FILES=`cat $LOGFILE | sed -n ''$LAST_RUN',$p' | grep "*deleting " | wc -l`
echo "Deleted files : $DELETED_FILES_NAMES"
echo "Deleted files count : $DELETED_FILES"
