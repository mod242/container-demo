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
echo "Begin to deploy $DB2_IMAGE_NAME:$DB2_IMAGE_TAG as $DB2_CONTAINER_NAME"
start_time_1=$(date +%s)
filename=$ScriptsDir/"status.log"
source $ScriptsDir/../setProperties.sh

function createDB2ConfigFolder() {
    echo "Create DB2 configuration folder..."
    db2_folder_array=($DB2_SCRIPT $DB2_STORAGE_FOLDER)
    if [ -d "$DB2_CONFIGFILES_LOC" ]; then
        echo "Removing existing $DB2_CONFIGFILES_LOC folder..."
        rm -fr "$DB2_CONFIGFILES_LOC"
    fi

    for folder in ${db2_folder_array[@]}
    do
        echo -e "  - creating $DB2_CONFIGFILES_LOC/$folder"
        mkdir -p $DB2_CONFIGFILES_LOC/$folder
    done
    # below is required otherwise db2instance can't be created due to permission issue
    if [[ "$OS" = "Mac" ]]; then
        chown -R 501:500 $DB2_CONFIGFILES_LOC
    fi
    echo "Created DB2 config folder successfully"
}

function copyDB2ConfigFiles() {
    echo "Copy DB2 configuration files start..."
    cd $ScriptsDir/config-files/DB2
    if (ls $GCDDB_SCRIPT && ls $OS1DB_SCRIPT && ls $ICNDB_SCRIPT && ls $ENV_LIST && ls $SETUP_DB && ls $DB2_ONE_SCRIPT) >/dev/null 2>&1 ; then
        cp -f $GCDDB_SCRIPT $OS1DB_SCRIPT $ICNDB_SCRIPT $ENV_LIST $SETUP_DB $DB2_ONE_SCRIPT $DB2_CONFIGFILES_LOC/$DB2_SCRIPT
    else
        echo "You missed some necessary db2 configuration files"
        exit_script
    fi
    cd $ScriptsDir
    echo "Copied DB2 configuration files to $DB2_CONFIGFILES_LOC successfully"
}

function deployDB2Container() {
    echo "Start Db2 docker container now..."
    containerID=`docker ps -a -q --filter name=$DB2_CONTAINER_NAME$`
    if [ "$containerID" = "" ]; then
        result=$(docker run -d -h $DB2_HOST_NAME --name $DB2_CONTAINER_NAME --add-host=$HOST_NAME:172.17.0.1 --restart=$DB2_RESTART --privileged=$DB2_PRIVILEGED -p $DB2_HTTP_PORT:$DB2_HTTP_PORT --env-file $DB2_CONFIGFILES_LOC/$DB2_SCRIPT/$ENV_LIST -v $DB2_CONFIGFILES_LOC/$DB2_SCRIPT:/tmp/db2_script -v $DB2_CONFIGFILES_LOC/$DB2_STORAGE_FOLDER:/db2fs $DB2_REGISTRY_URL/$DB2_IMAGE_NAME:$DB2_IMAGE_TAG)
    else
        docker ps -a -q --filter name=$DB2_CONTAINER_NAME | grep -q . && docker stop $DB2_CONTAINER_NAME && docker rm -fv $DB2_CONTAINER_NAME
        result=$(docker run -d -h $DB2_HOST_NAME --name $DB2_CONTAINER_NAME  --add-host=$HOST_NAME:172.17.0.1 --restart=$DB2_RESTART --privileged=$DB2_PRIVILEGED -p $DB2_HTTP_PORT:$DB2_HTTP_PORT --env-file $DB2_CONFIGFILES_LOC/$DB2_SCRIPT/$ENV_LIST -v $DB2_CONFIGFILES_LOC/$DB2_SCRIPT:/tmp/db2_script -v $DB2_CONFIGFILES_LOC/$DB2_STORAGE_FOLDER:/db2fs $DB2_REGISTRY_URL/$DB2_IMAGE_NAME:$DB2_IMAGE_TAG)
    fi
    if [[ "" = $result ]]; then
        echo -e "\033[31mStart $DB2_CONTAINER_NAME container failed \033[0m"
        exit
    fi
    echo "DB2 is starting please wait..."

    i=0
    while(($i<=$TIME_OUT*2))
        do
           tmp=`docker logs $DB2_CONTAINER_NAME | grep "Setup has completed."`
            if [ "$tmp"x = ""x ]; then
                let i++
                echo -e " $i. DB2 docker container still not ready, wait 30 seconds and check again...."
                sleep 30
            else
                echo -e "\033[36mDB2 docker container started successfully \033[0m"
                break
            fi
        done

        if [[ $i -eq $TIME_OUT*2 ]] ; then
            echo "DB2 can't start within 30 minutes, exiting now..."
            echo "Please check DB2 docker container log to check its status."
            exit_script
        fi
}

function createDB() {
  echo "Begin to create the GCDDB,ICNDB,OS1DB database..."
  containerID=`docker ps -a -q --filter name=$DB2_CONTAINER_NAME$`
  docker cp $DB2_CONFIGFILES_LOC/$DB2_SCRIPT/DB2_ONE_SCRIPT.sql $containerID:/database/config/db2inst1
  docker cp $DB2_CONFIGFILES_LOC/$DB2_SCRIPT/GCDDB.sh $containerID:/database/config/db2inst1
  docker cp $DB2_CONFIGFILES_LOC/$DB2_SCRIPT/ICNDB.sh $containerID:/database/config/db2inst1
  docker cp $DB2_CONFIGFILES_LOC/$DB2_SCRIPT/OS1DB.sh $containerID:/database/config/db2inst1
  docker cp $DB2_CONFIGFILES_LOC/$DB2_SCRIPT/setup_db.sh $containerID:/database/config/db2inst1
  docker exec -i $DB2_CONTAINER_NAME /bin/bash /database/config/db2inst1/setup_db.sh

if [ ! $? -eq 0 ] ; then
    echo -e "\033[31mFailed to create the databases. \033[0m"
    exit_script
fi
}

createDB2ConfigFolder
copyDB2ConfigFiles
deployDB2Container
createDB
end_time_1=$(date +%s)
duration_1=$((($end_time_1-$start_time_1)/60))
echo -e "\033[36mDeploy $DB2_CONTAINER_NAME container and create database took $duration_1 minute(s) \033[0m"
if [ $? -eq 0 ] ; then
    echo -e "\033[36mFinished deploying $DB2_CONTAINER_NAME container and created the databases successfully \033[0m"
    sed -i.bak 's/deployDB: NotCompleted/deployDB2: Completed/g' $filename
else
    exit_script
fi
echo "=========================================="
