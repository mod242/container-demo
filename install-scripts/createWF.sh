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
echo "Creating a P8 Workflow System...."

CPELibs=$ScriptsDir/CPELibs
if [[ -d $CPELibs ]]; then
	p8utils=$ScriptsDir/p8utils.jar:$CPELibs/Jace.jar:$CPELibs/log4j.jar:$CPELibs/pe.jar:$CPELibs/pe3pt.jar:$CPELibs/peResources.jar
else
	echo "There is no folder named $CPELibs"
fi

if [[ $DATABASE = "postgresql" ]] || [[ $DATABASE = "POSTGRESQL" ]]; then
	docker exec -i $JDK_CONTAINER_NAME java -cp $p8utils com.ibm.utils.PEInit "http://$HOST_NAME:$CPE_HTTP_PORT/wsi/FNCEWS40MTOM/" $P8ADMIN_USER $GLOBAL_PASSWORD  \
	$P8OS_NAME $ISOLATED_REGION $PE_REGION_NUMBER $PE_CONNPT_NAME $SYSTEM_ADMIN_GROUP $SYSTEM_CONFIG_GROUP "vwdata_ts" "vwindex_ts" "vwblob_ts"
else
	docker exec -i $JDK_CONTAINER_NAME java -cp $p8utils com.ibm.utils.PEInit "http://$HOST_NAME:$CPE_HTTP_PORT/wsi/FNCEWS40MTOM/" $P8ADMIN_USER $GLOBAL_PASSWORD  \
	$P8OS_NAME $ISOLATED_REGION $PE_REGION_NUMBER $PE_CONNPT_NAME $SYSTEM_ADMIN_GROUP $SYSTEM_CONFIG_GROUP "VWDATA_TS" "VWINDEX_TS" "VWBLOB_TS"

fi

if [ $? -eq 0 ] ; then
    echo -e "\033[36mFinished creating the Workflow System successfully \033[0m"
    echo -e "\033[36mConnection point: $PE_CONNPT_NAME:$PE_REGION_NUMBER, isolated region: $ISOLATED_REGION\033[0m"
	sed -i.bak 's/createWF: NotCompleted/createWF: Completed/g' $filename
else
    exit_script
fi
echo "=========================================="
