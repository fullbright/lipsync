#!/bin/sh -e
# Distributed under the terms of the BSD License.
# Copyright (c) 2011 Phil Cryer phil.cryer@gmail.com
# Source https://github.com/philcryer/lipsync

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
PARAM_CONF_FILE=/opt/helenasync/conf/helenasync.conf

echo "`whoami` is executing this script."

###############
# source config, define logfile
###############
if [ -e $PARAM_CONF_FILE ]; then
        . $PARAM_CONF_FILE
else
	echo "****** ERROR ******* : The configuration file $PARAM_CONF_FILE does not exist !"
fi

#loop to update often
while true; do
	echo "Going to sleep $UPDATE_FREQ" >> $LOGFILE
	sleep $UPDATE_FREQ
	echo "Retrieving data from servers" >> $LOGFILE
	$PULL_ALL_BIN
	echo "Done." >> $LOGFILE
done
