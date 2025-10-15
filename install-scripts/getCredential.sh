#!/bin/bash
#
# Licensed Materials - Property of IBM
# 5747-SM3
# (c) Copyright IBM Corp. 2017, 2021  All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
echo "=========================================="
date
echo "Begin to check user credential"
if [[ $ScriptsDir = "" ]]; then
	source ./d_utils.sh
	echo $ScriptsDir
fi

homefolder=$(cd $ScriptsDir/../ ; pwd)
REGISTRY_USERNAME=$(echo $REGISTRY_USERNAME)
REGISTRY_PASSWORD=$(echo $REGISTRY_PASSWORD)
GLOBAL_PASSWORD=$(echo $GLOBAL_PASSWORD)

function ask_user(){
	echo -e "\033[32mWhich way do you prefer to provide the API key?
==============================
1.) Copy the key file apiKey.json to $homefolder
2.) Input API key directly
3.) Quit
==============================\033[0m"
read -e -p "Please select 1, 2, or 3: " choice
if [ "$choice" == "1" ]; then
    echo -e "\033[32mDid you already put the it under $homefolder?
============
1.) Yes
2.) No
============\033[0m"
	read -e -p "Please select 1 or 2: " choice2
	if [ "$choice2" == "1" ] || [ "$choice2" == "Y" ] || [ "$choice2" == "y" ]; then
		getAPIKey
	else
		echo -e "\033[31mAPI key is required to continue, check our readme on how to get it.\033[0m"
		ask_user
	fi
elif [ "$choice" == "2" ]; then
    read -e -p "Please input your API key: " apikey
    key_length=$(echo ${#apikey})
    if [[ $key_length -lt 20 ]]; then
    	echo -e "\033[31mThe key you provide is not valid! \033[0m"
    	ask_user
	else
    	saveAPIkey $apikey
    fi
elif [ "$choice" == "3" ]; then
    exit_script
else
    echo -e "\033[31mYour input is unexpected.\033[0m"
    ask_user
fi
}

function saveAPIkey(){
	if [[ "Linux" = "$OS" ]]; then
		sed -i -e "s/APIKEY=.*/APIKEY=$1/g" $ScriptsDir/../setProperties.sh
	elif [[ "Mac" = "$OS" ]]; then
		sed -i "" -e "s/APIKEY=.*/APIKEY=$1/g" $ScriptsDir/../setProperties.sh
	fi
}

function getAPIKey(){
	keyfile=$ScriptsDir/../apiKey.json
	if [[ $APIKEY = "" ]]; then
		echo "No APIKEY provided, trying to get one now."
		if [ -f "$keyfile" ]; then
			echo "Tring to extract API key from $homefolder/apiKey.json."
			apikey=$(cat $keyfile | sed -n 's/"apiKey": "\(.*\)"/\1/p' | sed 's/^[ \t]*//g')
			saveAPIkey $apikey
		else
			echo "Didn't found API key file $homefolder/apiKey.json"
			ask_user
		fi
	else
		echo "Using existing API key in $homefolder/setProperties.sh"
	fi
}

# Get username and password of docker store
function getUserCredentail(){
	if [[ $REGISTRY_USERNAME = "" ]]; then
		echo -e "\033[32mPlease provide your authenticated docker store user id and password, it is required to download supporting images. \033[0m"
		read -e -p "Please input your user name: " username
		read -e -p "Please input your password: " password

		if [[ $username = "" ]] || [[ $password = "" ]]; then
			getUserCredentail
		else
			if [[ "Linux" = "$OS" ]]; then
				sed -i "s/REGISTRY_USERNAME=.*/REGISTRY_USERNAME=$username/g" $ScriptsDir/../setProperties.sh
				sed -i "s/REGISTRY_PASSWORD=.*/REGISTRY_PASSWORD=$password/g" $ScriptsDir/../setProperties.sh
			elif [[ "Mac" = "$OS" ]]; then
				sed -i "" "s/REGISTRY_USERNAME=.*/REGISTRY_USERNAME=$username/g" $ScriptsDir/../setProperties.sh
				sed -i "" "s/REGISTRY_PASSWORD=.*/REGISTRY_PASSWORD=$password/g" $ScriptsDir/../setProperties.sh
			fi
		fi
	elif [[ $REGISTRY_USERNAME != "" ]] && [[ $REGISTRY_PASSWORD = "" ]]; then
		echo -e "\033[31mPlease provide the password for $REGISTRY_USERNAME, it is required to download the images \033[0m"
		read -e -p "Please input your password: " password
		if [[ $password = "" ]]; then
			getUserCredentail
		else
			if [[ "Linux" = "$OS" ]]; then
				sed -i "s/REGISTRY_PASSWORD=.*/REGISTRY_PASSWORD=$password/g" $ScriptsDir/../setProperties.sh
			elif [[ "Mac" = "$OS" ]]; then
				sed -i "" "s/REGISTRY_PASSWORD=.*/REGISTRY_PASSWORD=$password/g" $ScriptsDir/../setProperties.sh
			fi
		fi
	else
		echo "Docker Hub User Id and password found in file, continue the installation now."
	fi
}

function setGlobalPassword(){
	if [[ $GLOBAL_PASSWORD = "" ]]; then
			echo -e "\033[32mPls provide a GLOBAL password. It will be set as LDAP and DB2 password. \033[0m"
			read -e -p "Please input a global password: " password
			if [[ $password = "" ]]; then
				setGlobalPassword
			else
				if [[ "Linux" = "$OS" ]]; then
					sed -i "s/GLOBAL_PASSWORD=.*/GLOBAL_PASSWORD=$password/g" $ScriptsDir/../setProperties.sh
				elif [[ "Mac" = "$OS" ]]; then
					sed -i "" "s/GLOBAL_PASSWORD=.*/GLOBAL_PASSWORD=$password/g" $ScriptsDir/../setProperties.sh
				fi
			fi
	fi
}

setGlobalPassword
if [[ $GET_IMAGE_FROM_BLUEMIX = "true" ]] || [[ $GET_IMAGE_FROM_BLUEMIX = "yes" ]]; then
	getAPIKey
# else
# 	getUserCredentail
fi
source $ScriptsDir/../setProperties.sh

if [ $? -eq 0 ] ;then
    echo -e "\033[36mFinished getting user's credential \033[0m"
else
    exit_script
fi
echo "=========================================="