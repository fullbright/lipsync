#!/bin/bash
#
#Loads offline items
#

PARAM_CONF_FILE=/opt/helenasync/conf/helenasync.conf

###############
# source config, define logfile
###############
if [ -e $PARAM_CONF_FILE ]; then
        . $PARAM_CONF_FILE
else
	echo "****** ERROR ******* : The configuration file $PARAM_CONF_FILE does not exist !"
fi

echo "Reading offline files"
offlinefiles=$(ls $OFFLINE_DIR)

echo $offlinefiles

for x in $offlinefiles
do
	#cat $OFFLINE_DIR/$x
	offlinefile=$OFFLINE_DIR$x
	echo "Processsing file " $offlinefile

	sourcepath=$(cat $offlinefile |  grep srcfile | cut -d"=" -f2)
    	echo "Source path: $sourcepath"

	server=$(cat $offlinefile |  grep server | cut -d"=" -f2)
    	echo "Source path: $server"

	dest=$(cat $offlinefile |  grep dest | cut -d"=" -f2)
    	echo "Source path: $dest"

	echo "Pushing offline file to server"
	echo "Excuting command : rsync $sourcepath $server:$dest"
	rsync $sourcepath $server:$dest

	# if rsync was successfull, remove the file
	returncode=$?
	echo "Return code is :" $returncode

	if [ "${returncode}" -eq "0" ]; then
		echo "Command was successfull, removing file $offlinefile"
		echo "executing command : rm $offlinefile"
		#rm $offlinefile
	else
		echo "Error occured when executing command. Please, try to sync later"
	fi


done


