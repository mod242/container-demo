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
echo "Starting to deploy $ICN_IMAGE_NAME:$ICN_IMAGE_TAG as $ICN_CONTAINER_NAME"
filename=$ScriptsDir/"status.log"

#create config folder for ICN
function createICNConfigFolder() {
    echo "Create ICN configuration folder..."
    icn_folder_array=($ICN_VIEWERLOG_FOLDER $ICN_VIEWERCACHE_FOLDER $ICN_PLUGINS_FOLDER $ICN_ASPERA_FOLDER $ICN_LOGS_FOLDER $ICN_OVERRIDES_FOLDER)
    if [ -d "$ICN_CONFIGFILES_LOC" ] ;then
	echo "Removing existing $ICN_CONFIGFILES_LOC folder..."
        rm -fr "$ICN_CONFIGFILES_LOC"
    fi
    for folder in ${icn_folder_array[@]}
        do
            echo -e "  - creating $ICN_CONFIGFILES_LOC/$folder"
            mkdir -p $ICN_CONFIGFILES_LOC/$folder
            chown -R $U_UID:$G_GID $ICN_CONFIGFILES_LOC/$folder
        done
    echo "Create ICN configuration folder successfully"
}

#move CPE configuration files to mount folder
function copyICNConfigFiles() {
    echo "Copy ICN configuration files start..."
    if [ -d "$ScriptsDir/config-files/common" ]; then
        cd $ScriptsDir/config-files/common
         if [[ $DATABASE = "postgresql" ]] || [[ $DATABASE = "POSTGRESQL" ]]; then
            if (ls $PGJCC4 && ls $LDAP && ls $PGJCCDRIVER) >/dev/null 2>&1 ;then
                cp -f $PGJCC4 $LDAP $PGJCCDRIVER $ICN_CONFIGFILES_LOC/$ICN_OVERRIDES_FOLDER
            else
                echo "You missed some necessary common configuration files"
                exit_script
            fi
        else
            if (ls $DB2JCC_LICENSE_CU && ls $DB2JCC4 && ls $LDAP && ls $DB2JCCDRIVER) >/dev/null 2>&1 ;then
                cp -f $DB2JCC_LICENSE_CU $DB2JCC4 $LDAP $DB2JCCDRIVER $ICN_CONFIGFILES_LOC/$ICN_OVERRIDES_FOLDER
            else
                echo "You missed some necessary common configuration files"
                exit_script
            fi
        fi
        # Default keystore for HTTPS (the key.jks shipped in the image cannot be opened)
        cp -f keystore.xml $ICN_CONFIGFILES_LOC/$ICN_OVERRIDES_FOLDER
    else
        echo "The configuration file path $ScriptsDir/config-files/common does not exist"
        exit 1
    fi

    if [ -d "$ScriptsDir/config-files/ICN" ] ;then
        cd $ScriptsDir/config-files/ICN
        if (ls $ICNDS) >/dev/null 2>&1 ;then
            cp -f $ICNDS $ICN_CONFIGFILES_LOC/$ICN_OVERRIDES_FOLDER
        else
            echo "You missed some necessary ICN configuration files"
            exit_script
        fi
    else
        echo "The configuration file path $ScriptsDir/config-files/ICN does not exist"
        exit_script
    fi
    chown -R $U_UID:$G_GID $ICN_CONFIGFILES_LOC
    chmod -R 777 $ICN_CONFIGFILES_LOC
    echo "Copied ICN configuration files to $ICN_OVERRIDES_FOLDER successfully"
}

function deployICNContainer() {
    echo "Start ICN docker container now..."
    icnContainerId=`docker ps -a -q --filter name=$ICN_CONTAINER_NAME$`
    if [ "$icnContainerId" = "" ]; then
        result=$(docker run -d --name $ICN_CONTAINER_NAME --add-host=$HOST_NAME:host-gateway --restart=$ICN_RESTART -p $ICN_HTTP_PORT:9080 -p $ICN_HTTPS_PORT:9443 -u $U_UID -e disableFIPS=true -e LICENSE=accept -e ICNDBTYPE=$DATABASE -e ICNJNDIDS=ECMClientDS -e ICNSCHEMA=ICNDB -e ICNTS=ICNDBTS -e ICNADMIN=$P8ADMIN_USER -e navigatorMode=0 -e JVM_CUSTOMIZE_OPTIONS=-DFileNet.WSI.AutoDetectLTPAToken=true -v $ICN_CONFIGFILES_LOC/$ICN_PLUGINS_FOLDER:/opt/ibm/plugins -v $ICN_CONFIGFILES_LOC/$ICN_VIEWERLOG_FOLDER:/opt/ibm/viewerconfig/logs -v $ICN_CONFIGFILES_LOC/$ICN_VIEWERCACHE_FOLDER:/opt/ibm/viewerconfig/cache -v $ICN_CONFIGFILES_LOC/$ICN_LOGS_FOLDER:/opt/ibm/wlp/usr/servers/defaultServer/logs -v $ICN_CONFIGFILES_LOC/$ICN_ASPERA_FOLDER:/opt/ibm/Aspera -v $ICN_CONFIGFILES_LOC/$ICN_OVERRIDES_FOLDER:/opt/ibm/wlp/usr/servers/defaultServer/configDropins/overrides $ICN_REGISTRY_URL/$ICN_IMAGE_NAME:$ICN_IMAGE_TAG)
    else
        docker ps -a -q --filter name=$ICN_CONTAINER_NAME | grep -q . && docker stop $ICN_CONTAINER_NAME && docker rm -fv $ICN_CONTAINER_NAME
        result=$(docker run -d --name $ICN_CONTAINER_NAME --add-host=$HOST_NAME:host-gateway --restart=$ICN_RESTART -p $ICN_HTTP_PORT:9080 -p $ICN_HTTPS_PORT:9443 -u $U_UID -e disableFIPS=true -e LICENSE=accept -e ICNDBTYPE=$DATABASE -e ICNJNDIDS=ECMClientDS -e ICNSCHEMA=ICNDB -e ICNTS=ICNDBTS -e ICNADMIN=$P8ADMIN_USER -e navigatorMode=0 -e JVM_CUSTOMIZE_OPTIONS=-DFileNet.WSI.AutoDetectLTPAToken=true -v $ICN_CONFIGFILES_LOC/$ICN_PLUGINS_FOLDER:/opt/ibm/plugins -v $ICN_CONFIGFILES_LOC/$ICN_VIEWERLOG_FOLDER:/opt/ibm/viewerconfig/logs -v $ICN_CONFIGFILES_LOC/$ICN_VIEWERCACHE_FOLDER:/opt/ibm/viewerconfig/cache -v $ICN_CONFIGFILES_LOC/$ICN_LOGS_FOLDER:/opt/ibm/wlp/usr/servers/defaultServer/logs -v $ICN_CONFIGFILES_LOC/$ICN_ASPERA_FOLDER:/opt/ibm/Aspera -v $ICN_CONFIGFILES_LOC/$ICN_OVERRIDES_FOLDER:/opt/ibm/wlp/usr/servers/defaultServer/configDropins/overrides $ICN_REGISTRY_URL/$ICN_IMAGE_NAME:$ICN_IMAGE_TAG)
    fi
    if [[ "" = $result ]]; then
        echo -e "\033[31mStart $ICN_CONTAINER_NAME container failed \033[0m"
        exit
    fi
    echo "Deployed Navigator container successfully"
}

createICNConfigFolder
copyICNConfigFiles
deployICNContainer

if [ $? -eq 0 ] ;then
    echo -e "\033[36mFinished deploying $ICN_CONTAINER_NAME container successfully \033[0m"
	sed -i.bak 's/deployICN: NotCompleted/deployICN: Completed/g' $filename
else
    exit_script
fi
echo "=========================================="
