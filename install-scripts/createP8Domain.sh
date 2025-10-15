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
source $ScriptsDir/../setProperties.sh

echo "Create P8 Domain $P8DOMAIN_NAME"
CPELibs=$ScriptsDir/CPELibs
if [[ -d "$CPELibs" ]]; then
	p8utils=$ScriptsDir/p8utils.jar:$CPELibs/Jace.jar:$CPELibs/log4j.jar:$CPELibs/stax-api.jar:$CPELibs/xlxpScanner.jar:$CPELibs/xlxpScannerUtils.jar
else
	echo "There is no folder named $CPELibs"
fi

i=0
while(($i<=$TIME_OUT*2))
do
	isCPEOnLine=$(curl -s -I http://localhost:9080/acce | grep 302)
	if [[ "$isCPEOnLine" != "" ]] ; then
		isCPEReady=$(cat $CPE_CONFIGFILES_LOC/$CPE_LOGS_FOLDER/$CPE_CONTAINER_HOST_NAME/messages.log | grep "DetailedStatusReport.*Initialization successful")
		if [[ "$isCPEReady" != "" ]]; then
			sleep 60s
			docker exec -i $JDK_CONTAINER_NAME java -cp $p8utils com.ibm.CETools "createDomain" "$HOST_NAME" $CPE_HTTP_PORT $P8ADMIN_USER $GLOBAL_PASSWORD $P8DOMAIN_NAME "IBM" "$HOST_NAME" $LDAP_PORT "cn=P8Admin,dc=ecm,dc=ibm,dc=com" $GLOBAL_PASSWORD "dc=ecm,dc=ibm,dc=com" "dc=ecm,dc=ibm,dc=com" "P8Admins" "GeneralUsers"
			if [ ! $? -eq 0 ] ; then
		        echo -e "\033[31mSomething wrong when creating P8 domain. \033[0m"
		        echo -e "\033[31mCheck $CPE_CONFIGFILES_LOC/$CPE_LOGS_FOLDER/$CPE_CONTAINER_HOST_NAME/messages.log to see if any error \033[0m"
		        exit_script
			fi
			break
		else
			echo "$i. Liberty started but CPE not ready yet, wait 30 seconds and try again...."
			sleep 30s
			let i++
		fi
	else
		echo "$i. Liberty has not started yet, wait 30 seconds and try again...."
		sleep 30s
		let i++
	fi
done

if [[ $i -eq $TIME_OUT*2 ]] ; then
	echo -e "\033[31mCPE is not ready in 30 minutes, exiting now... \033[0m"
	echo -e "\033[31m1. Check whether the CPE container is running \033[0m"
	echo -e "\033[31m2. Check log file $CPE_CONFIGFILES_LOC/$CPE_LOGS_FOLDER/$CPE_CONTAINER_HOST_NAME/messages.log for errors. \
        There should be a message like '[DetailedStatusReport]: Initialization successful'	 \033[0m"
	exit_script
fi

if [ $? -eq 0 ] ;then
    echo -e "\033[36mFinished creating CPE Domain '$P8DOMAIN_NAME' successfully \033[0m"
	sed -i.bak 's/createP8Domain: NotCompleted/createP8Domain: Completed/g' $filename
else
    exit_script
fi
echo "=========================================="
