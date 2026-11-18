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
echo "Begin to deploy $LDAP_IMAGE_NAME:$LDAP_IMAGE_TAG as $LDAP_CONTAINER_NAME"
filename=$ScriptsDir/"status.log"
source $ScriptsDir/../setProperties.sh

function startLDAP() {
    ldapContainerId=`docker ps -a -q --filter name=$LDAP_CONTAINER_NAME$`
    if [ "$ldapContainerId" = "" ]; then
        result=$(docker run -d -t --name=$LDAP_CONTAINER_NAME --add-host=$HOST_NAME:host-gateway --restart=$LDAP_RESTART -p $LDAP_PORT:389 -p $LDAP_HTTP_PORT:80 --env LDAP_BASE_DN=$LDAP_BASE_DN --env LDAP_DOMAIN=$LDAP_DOMAIN --env LDAP_ADMIN_PASSWORD=$GLOBAL_PASSWORD $LDAP_REGISTRY_URL/$LDAP_IMAGE_NAME:$LDAP_IMAGE_TAG bash)
    else
        docker stop $LDAP_CONTAINER_NAME && docker rm -fv $LDAP_CONTAINER_NAME
        result=$(docker run -d -t --name=$LDAP_CONTAINER_NAME --add-host=$HOST_NAME:host-gateway --restart=$LDAP_RESTART -p $LDAP_PORT:389 -p $LDAP_HTTP_PORT:80 --env LDAP_BASE_DN=$LDAP_BASE_DN --env LDAP_DOMAIN=$LDAP_DOMAIN --env LDAP_ADMIN_PASSWORD=$GLOBAL_PASSWORD $LDAP_REGISTRY_URL/$LDAP_IMAGE_NAME:$LDAP_IMAGE_TAG bash)
    fi
    if [[ "" = $result ]]; then
        echo -e "\033[31mStart $LDAP_CONTAINER_NAME container failed \033[0m"
        exit
    fi
}

function changePassword(){
    if [ "$GLOBAL_PASSWORD"x = "FileNet"x ]; then
        echo "No need to change the password, will use the default value"
    else
        i=0
        while(($i<=$TIME_OUT*2))
        do
            isLDAPReady=$(docker logs ldap | grep "openldap")
            if [[ $isLDAPReady != "" ]]; then
                source $ScriptsDir/modifyLdapPassword.sh
                break
            else
                echo "$i. LDAP is not ready yet, wait 5 seconds and retry again...."
                sleep 5s
                let i++
            fi
        done
        if [[ $i -eq $TIME_OUT*2 ]] ;then
            echo -e "\033[31mLDAP is not ready in 1 minute, something must be wrong, exit now... \033[0m"
            echo -e "\033[31m1. Pls check whether LDAP docker container running \033[0m"
            echo -e "\033[31m2. use command 'docker logs ldap' to see if any error \033[0m"
            exit_script
        fi
    fi
}

function addLdapUsers(){
        i=0
        while(($i<=$TIME_OUT*2))
        do
            isLDAPReady=$(docker logs ldap | grep "openldap")
            if [[ $isLDAPReady != "" ]]; then
                source $ScriptsDir/addLdapUsers.sh
                break
            else
                echo "$i. LDAP is not ready yet, wait 5 seconds and retry again...."
                sleep 5s
                let i++
            fi
        done
        if [[ $i -eq $TIME_OUT*2 ]] ;then
            echo -e "\033[31mLDAP is not ready in 30 minutes, exiting now... \033[0m"
            echo -e "\033[31m1. Please check whether LDAP container is running \033[0m"
            echo -e "\033[31m2. Use command 'docker logs ldap' to check for any error \033[0m"
            exit_script
        fi
}


function checkLDAPStatus(){
    i=0
        while(($i<=$TIME_OUT*2))
        do
            isLDAPReady=$(docker logs ldap | grep "openldap")
            if [[ "$isLDAPReady" != "" ]]; then
             echo "ldap container started, check ldap service now."
              isLDAPonLine=$(docker exec -i $LDAP_CONTAINER_NAME service slapd status | grep running)
                if [[ "$isLDAPonLine" = "" ]]; then
                    echo "Need to restart LDAP service now."
                    docker exec -i ldap service slapd start
                    if [ $? -eq 0 ] ;then
                        echo "Restart done."
                        docker exec -i ldap service slapd status
                        break
                    fi
                else
                    echo "LDAP service is ready."
                    break
                fi
            else
                echo "$i. LDAP is not ready yet, wait 10 seconds and check again...."
                sleep 10s
                let i++
            fi
        done
        if [[ $i -eq $TIME_OUT*2 ]] ;then
            echo -e "\033[31mLDAP is not ready in 30 minutes, exiting now... \033[0m"
            echo -e "\033[31m1. Please check whether the LDAP container is running\033[0m"
            echo -e "\033[31m2. Use command 'docker logs ldap' to check for any errors\033[0m"
            echo -e "\033[31m3. Use command 'docker exec -i ldap service slapd status' to check if the OpenLDAP service is running\033[0m"
            exit_script
        fi
}

startLDAP
checkLDAPStatus
# changePassword
addLdapUsers

if [ $? -eq 0 ] ;then
    echo -e "\033[36mFinished deploying $LDAP_CONTAINER_NAME container successfully \033[0m"
     sed -i.bak 's/deployLDAP: NotCompleted/deployLDAP: Completed/g' $filename
else
    exit_script
fi
echo "=========================================="
