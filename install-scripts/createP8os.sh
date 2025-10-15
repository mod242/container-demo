#!/bin/bash
#
# Licensed Materials - Property of IBM
# 5747-SM3
# (c) Copyright IBM Corp. 2017, 2021  All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
echo "=========================================="
date
filename=$ScriptsDir/"status.log"

if [[ $ScriptsDir = "" ]]; then
	source ./d_utils.sh
	echo $ScriptsDir
fi
echo "Create Object Store: $P8OS_NAME"

CPELibs=$ScriptsDir/CPELibs
if [[ -d $CPELibs ]]; then
	p8utils=$ScriptsDir/p8utils.jar:$CPELibs/Jace.jar:$CPELibs/log4j.jar:$CPELibs/stax-api.jar:$CPELibs/xlxpScanner.jar:$CPELibs/xlxpScannerUtils.jar
else
	echo "There is no folder named $CPELibs"
fi

i=0
while(($i<=$TIME_OUT*2))
do
	isDomainReady=$(cat $CPE_CONFIGFILES_LOC/$CPE_LOGS_FOLDER/$CPE_CONTAINER_HOST_NAME/messages.log | grep "PE Server started")
	if [[ "$isDomainReady" != "" ]] ; then
			docker exec -i $JDK_CONTAINER_NAME java -cp $p8utils com.ibm.CETools "createObjectStore" $HOST_NAME $CPE_HTTP_PORT $P8ADMIN_USER $GLOBAL_PASSWORD $P8OS_NAME "FNOSDS" "FNOSDSXA" $P8ADMIN_GROUP "GeneralUsers" "" ""

		if [ ! $? -eq 0 ] ;then
	        echo -e "\033[31m Error in creating the P8 Object Store. \033[0m"
	        echo -e "\033[31m Check log file $CPE_CONFIGFILES_LOC/$CPE_LOGS_FOLDER/$CPE_CONTAINER_HOST_NAME/messages.log for errors \033[0m"
	        exit_script
		fi
		break
	else
		echo "$i. CPE domain is not ready yet, wait 30 seconds and try again...."
		sleep 30s
		let i++
	fi
done
if [[ $i -eq $TIME_OUT*2 ]] ; then
	echo -e "\033[31m CPE domain is not ready in 30 minutes, exiting now... \033[0m"
	echo -e "\033[31m Check log file $CPE_CONFIGFILES_LOC/$CPE_LOGS_FOLDER/$CPE_CONTAINER_HOST_NAME/messages.log for errors\033[0m"
	exit_script
fi

if [ $? -eq 0 ] ; then
    echo -e "\033[36mFinished creating Object Store successfully \033[0m"
	sed -i.bak 's/createP8os: NotCompleted/createP8os: Completed/g' $filename
else
    exit_script
fi
echo "=========================================="
