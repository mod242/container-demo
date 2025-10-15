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
echo "Starting to deploy $CPE_IMAGE_NAME:$CPE_IMAGE_TAG as $CPE_CONTAINER_NAME"
filename=$ScriptsDir/"status.log"

function createCPEConfigFolder() {
    echo "Create CPE configuration folder..."
    cpe_folder_array=($CPE_FILENET_FOLDER $CPE_LOGS_FOLDER $CPE_ASA_FOLDER $CPE_TEXTEXT_FOLDER $CPE_ICMRULES_FOLDER $CPE_OVERRIDES_FOLDER $CPE_BOOTSTRAP_FOLDER)
    if [ -d "$CPE_CONFIGFILES_LOC" ] ;then
        echo "Removing existing $CPE_CONFIGFILES_LOC folder..."
        rm -fr "$CPE_CONFIGFILES_LOC"
    fi
    for folder in ${cpe_folder_array[@]}
        do
            echo -e "  - creating $CPE_CONFIGFILES_LOC/$folder"
            mkdir -p $CPE_CONFIGFILES_LOC/$folder
            chown -R $U_UID:$G_GID $CPE_CONFIGFILES_LOC/$folder
        done
    echo "Created CPE configuration folder successfully"
}

#copy CPE configuration files to mount folder
function copyCPEConfigFiles() {
    echo "Copy CPE configuration files start..."
    if [ -d "$ScriptsDir/config-files/common" ]; then
        cd $ScriptsDir/config-files/common
        if [[ $DATABASE = "postgresql" ]] || [[ $DATABASE = "POSTGRESQL" ]]; then
            if (ls $PGJCC4 && ls $LDAP && ls $PGJCCDRIVER) >/dev/null 2>&1 ;then
                cp -f $PGJCC4 $LDAP $PGJCCDRIVER $CPE_CONFIGFILES_LOC/$CPE_OVERRIDES_FOLDER
            else
                echo "You missed some necessary common configuration files"
                exit_script
            fi
        else
            if (ls $DB2JCC_LICENSE_CU && ls $DB2JCC4 && ls $LDAP && ls $DB2JCCDRIVER) >/dev/null 2>&1 ;then
                cp -f $DB2JCC_LICENSE_CU $DB2JCC4 $LDAP $DB2JCCDRIVER $CPE_CONFIGFILES_LOC/$CPE_OVERRIDES_FOLDER
            else
                echo "You missed some necessary common configuration files"
                exit_script
            fi
        fi
        
    else
        echo "The configuration file path $ScriptsDir/config-files/common does not exist"
        exit_script
    fi

    cd $ScriptsDir/config-files/CPE
    if (ls $FNGCDDS && ls $FNDOSDS && ls $PROPS) >/dev/null 2>&1 ;then
        cp -f $FNGCDDS $FNDOSDS $CPE_CONFIGFILES_LOC/$CPE_OVERRIDES_FOLDER
        cp -f $PROPS $CPE_CONFIGFILES_LOC/$CPE_BOOTSTRAP_FOLDER
    else
        echo "You missed some necessary cpe configuration files"
        exit_script
    fi
	chown -R $U_UID:$G_GID $CPE_CONFIGFILES_LOC
	chmod -R 777 $CPE_CONFIGFILES_LOC
    echo "Copied CPE configuration files to $CPE_CONFIGFILES_LOC successfully"
}

function deployCPEContainer() {
    echo "Start CPE docker container now..."
    cpeContainerId=`docker ps -a -q --filter name=$CPE_CONTAINER_NAME$`
    if [ "$cpeContainerId" = "" ]; then
        result=$(docker run -d --name $CPE_CONTAINER_NAME --add-host=$HOST_NAME:172.17.0.1 --restart=$CPE_RESTART -p $CPE_HTTP_PORT:9080 -p $CPE_HTTPS_PORT:9443 --hostname=$CPE_CONTAINER_HOST_NAME -u $U_UID -e GCDJNDINAME=FNGCDDS -e GCDJNDIXANAME=FNGCDDSXA -e LICENSEMODEL=FNCM.PVUNonProd -e LICENSE=accept -e JVM_CUSTOMIZE_OPTIONS=-DFileNet.WSI.AutoDetectLTPAToken=true -e disableFIPS=true -v $CPE_CONFIGFILES_LOC/$CPE_BOOTSTRAP_FOLDER:/opt/ibm/wlp/usr/servers/defaultServer/lib/bootstrap -v $CPE_CONFIGFILES_LOC/$CPE_ASA_FOLDER:/opt/ibm/asa -v $CPE_CONFIGFILES_LOC/$CPE_TEXTEXT_FOLDER:/opt/ibm/textext -v $CPE_CONFIGFILES_LOC/$CPE_ICMRULES_FOLDER:/opt/ibm/icmrules -v $CPE_CONFIGFILES_LOC/$CPE_LOGS_FOLDER:/opt/ibm/wlp/usr/servers/defaultServer/logs -v $CPE_CONFIGFILES_LOC/$CPE_FILENET_FOLDER:/opt/ibm/wlp/usr/servers/defaultServer/FileNet -v $CPE_CONFIGFILES_LOC/$CPE_OVERRIDES_FOLDER:/opt/ibm/wlp/usr/servers/defaultServer/configDropins/overrides $CPE_REGISTRY_URL/$CPE_IMAGE_NAME:$CPE_IMAGE_TAG)
    else
        docker ps -a -q --filter name=$CPE_CONTAINER_NAME | grep -q . && docker stop $CPE_CONTAINER_NAME && docker rm -fv $CPE_CONTAINER_NAME
        result=$(docker run -d --name $CPE_CONTAINER_NAME --add-host=$HOST_NAME:172.17.0.1 --restart=$CPE_RESTART -p $CPE_HTTP_PORT:9080 -p $CPE_HTTPS_PORT:9443 --hostname=$CPE_CONTAINER_HOST_NAME -u $U_UID -e GCDJNDINAME=FNGCDDS -e GCDJNDIXANAME=FNGCDDSXA -e LICENSEMODEL=FNCM.PVUNonProd -e LICENSE=accept -e JVM_CUSTOMIZE_OPTIONS=-DFileNet.WSI.AutoDetectLTPAToken=true -e disableFIPS=true -v $CPE_CONFIGFILES_LOC/$CPE_BOOTSTRAP_FOLDER:/opt/ibm/wlp/usr/servers/defaultServer/lib/bootstrap -v $CPE_CONFIGFILES_LOC/$CPE_ASA_FOLDER:/opt/ibm/asa -v $CPE_CONFIGFILES_LOC/$CPE_TEXTEXT_FOLDER:/opt/ibm/textext -v $CPE_CONFIGFILES_LOC/$CPE_ICMRULES_FOLDER:/opt/ibm/icmrules -v $CPE_CONFIGFILES_LOC/$CPE_LOGS_FOLDER:/opt/ibm/wlp/usr/servers/defaultServer/logs -v $CPE_CONFIGFILES_LOC/$CPE_FILENET_FOLDER:/opt/ibm/wlp/usr/servers/defaultServer/FileNet -v $CPE_CONFIGFILES_LOC/$CPE_OVERRIDES_FOLDER:/opt/ibm/wlp/usr/servers/defaultServer/configDropins/overrides $CPE_REGISTRY_URL/$CPE_IMAGE_NAME:$CPE_IMAGE_TAG)
    fi
    if [[ "" = $result ]]; then
        echo -e "\033[31mStart $CPE_CONTAINER_NAME container failed \033[0m"
        exit
    fi
    echo "Deployed CPE container successfully"
}

createCPEConfigFolder
copyCPEConfigFiles
deployCPEContainer

if [ $? -eq 0 ] ;then
    echo -e "\033[36mFinished deploying $CPE_CONTAINER_NAME container successfully \033[0m"
	sed -i.bak 's/deployCPE: NotCompleted/deployCPE: Completed/g' $filename
else
    exit_script

fi
echo "=========================================="
