#!/bin/bash
#
# Licensed Materials - Property of IBM
# 5747-SM3
# (c) Copyright IBM Corp. 2017, 2021  All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
echo "=========================================="
date
if [[ $ScriptsDir = "" ]]; then
    source ./d_utils.sh
    echo $ScriptsDir
fi
echo "Begin to deploy $JDK_IMAGE_NAME:$JDK_IMAGE_TAG as $JDK_CONTAINER_NAME"
filename=$ScriptsDir/"status.log"
source $ScriptsDir/../setProperties.sh

# Get fully-qualified hostname for the deploy run parameter add-host
HOST_NAME=$(hostname -f)

function deployJDKContainer() {
    echo "Start JDK docker container now..."
    containerID=`docker ps -a -q --filter name=$JDK_CONTAINER_NAME$`
    if [ "$containerID" = "" ]; then
        result=$(docker run -d -t --name $JDK_CONTAINER_NAME --add-host=$HOST_NAME:172.17.0.1 -v $ScriptsDir:$ScriptsDir $JDK_IMAGE_NAME:$JDK_IMAGE_TAG)
    else
        docker ps -a -q --filter name=$JDK_CONTAINER_NAME | grep -q . && docker stop $JDK_CONTAINER_NAME && docker rm -fv $JDK_CONTAINER_NAME
        result=$(docker run -d -t --name $JDK_CONTAINER_NAME --add-host=$HOST_NAME:172.17.0.1 -v $ScriptsDir:$ScriptsDir $JDK_IMAGE_NAME:$JDK_IMAGE_TAG)
    fi
    if [[ "" = $result ]]; then
        echo -e "\033[31mStart $JDK_CONTAINER_NAME container failed \033[0m"
        exit_script
    fi
}

deployJDKContainer

if [ $? -eq 0 ] ;then
    echo -e "\033[36mFinished deploying $JDK_CONTAINER_NAME container successfully \033[0m"
    sed -i.bak 's/deployJDK: NotCompleted/deployJDK: Completed/g' $filename
else
    exit_script
fi
echo "=========================================="
