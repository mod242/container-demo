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
	source ./install-scripts/d_utils.sh
	echo $ScriptsDir
fi
source $ScriptsDir/../setProperties.sh

function userInput() {
	echo -e "\033[32mAre you sure you want to remove the Container PIT components?(y/n)\033[0m"
	read -e choice
	if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
		echo "\033[31mStarting environment cleanup.....\033[0m"
	elif [[ "$choice" == "n" || "$choice" == "N" ]]; then
		echo "\033[31mAborting environment cleanup.....\033[0m"
		exit
	else
		echo -e "\033[31mUnexpected input\033[0m"
		userInput
	fi
}

function cleanupCommonLinux(){

    echo "Cleanup for Linux"

    # Stop all running containers
	  echo "Stopping and removing all running containers..."
    docker ps -a|grep "ibmjdk"|awk '{print $1}'|xargs docker stop > /dev/null
    docker ps -a|grep "icn"|awk '{print $1}'|xargs docker stop > /dev/null
    docker ps -a|grep "cpe"|awk '{print $1}'|xargs docker stop > /dev/null
    docker ps -a|grep "ldap"|awk '{print $1}'|xargs docker stop > /dev/null
    docker ps -a|grep "db2"|awk '{print $1}'|xargs docker stop > /dev/null

    # Remove all stopped containers
    docker rm $(docker ps -a -q)

	# Remove container images
	echo "Removing container images..."
	docker rmi $(docker images --format "{{.ID}}" $DOCKER_REGISTRY_URL/$ICN_IMAGE_NAME:$ICN_IMAGE_TAG)
	docker rmi $(docker images --format "{{.ID}}" $DOCKER_REGISTRY_URL/$CPE_IMAGE_NAME:$CPE_IMAGE_TAG)
	docker rmi $(docker images --format "{{.ID}}" $JDK_IMAGE_NAME:$JDK_IMAGE_TAG)


	# Remove installed python and ldap libraries
	echo "Removing installed python and ldap libraries..."
	sudo pip uninstall docker-py -y
	sudo apt-get remove python3-pip -y
	sudo apt-get remove ldap-utils -y

}

function cleanupCommonMac()
{
    echo "Cleanup for Mac"

    # Stop all running containers
    echo "Stopping and removing all running containers..."
	  docker ps -a|grep "ibmjdk"|awk '{print $1}'|xargs docker stop > /dev/null
    docker ps -a|grep "icn"|awk '{print $1}'|xargs docker stop > /dev/null
    docker ps -a|grep "cpe"|awk '{print $1}'|xargs docker stop > /dev/null
    docker ps -a|grep "ldap"|awk '{print $1}'|xargs docker stop > /dev/null
    docker ps -a|grep "db2"|awk '{print $1}'|xargs docker stop > /dev/null

    # Remove all stopped containers
    docker rm $(docker ps -a -q)

	# Remove container images
	echo "Removing container images..."
	docker rmi $(docker images --format "{{.ID}}" $DOCKER_REGISTRY_URL/$ICN_IMAGE_NAME:$ICN_IMAGE_TAG)
	docker rmi $(docker images --format "{{.ID}}" $DOCKER_REGISTRY_URL/$CPE_IMAGE_NAME:$CPE_IMAGE_TAG)
	docker rmi $(docker images --format "{{.ID}}" $JDK_IMAGE_NAME:$JDK_IMAGE_TAG)

}

function cleanupFolders()
{
	echo "Cleaning all container mount folders..."

	# Delete mount volumes folders
	rm -fr $CPE_CONFIGFILES_LOC
	rm -fr $ICN_CONFIGFILES_LOC
	rm -fr $DB2_CONFIGFILES_LOC

	# Delete container extraction folder
	rm -rf $TEMP_LOCATION

	# Delete the install status file
	rm -f $ScriptsDir/status.log*

}

userInput

if [[ "Linux"x = "$OS"x ]]; then
    cleanupCommonLinux
    if [ ! $? -eq 0 ] ;then
  	echo "Failed to stop and remove containers, exiting now."
  	exit
    fi
elif [[ "Mac"x = "$OS"x ]]; then
    cleanupCommonMac
    if [ ! $? -eq 0 ] ;then
  	echo "Failed to stop and remove containers, exiting now."
  	exit
    fi
fi

cleanupFolders
