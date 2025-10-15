#!/bin/bash
#
# Licensed Materials - Property of IBM
# 5747-SM3
# (c) Copyright IBM Corp. 2017, 2021  All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
echo "=========================================="
echo "Begin ending actions"
filename=$ScriptsDir/"status.log"
if [[ $ScriptsDir = "" ]]; then
	source ./d_utils.sh
	echo $ScriptsDir
fi

if [[ $DATABASE = "db2" ]] || [[ $DATABASE = "DB2" ]]; then
	echo "Set DB2 User to never expire"
	docker exec -it db2 bash -c "chage -E -1 -M -1 db2inst1"
fi


function stopJDKContainer() {
        echo "Remove JDK docker container now..."
        containerID=`docker ps -a -q --filter name=$JDK_CONTAINER_NAME$`
        if [ "$containerID" != "" ]; then
                result=$(docker rm -f $containerID)
        fi
        if [[ "" = $result ]]; then
          echo "$JDK_CONTAINER_NAME container is still running, you can use command 'docker stop $JDK_CONTAINER_NAME' to stop it."
          echo "Stopping it won't affect your FileNet Content Manager environment and can free some resource on your host."
		else
			echo "JDK container '$JDK_CONTAINER_NAME' removed successfully."
        fi
}

function urlOutput(){
	echo -e "\033[36m
	*******************************************************************************************
	The scripts finished successfully, now you can login to your applications using these URLs:
	IBM Content Platform Engine: https://$HOST_NAME:9443/acce   Login: P8Admin/$GLOBAL_PASSWORD
	IBM Content Navigator: https://$HOST_NAME:9444/navigator    Login: P8Admin/$GLOBAL_PASSWORD
	*******************************************************************************************
	\033[0m"
}

stopJDKContainer
urlOutput
