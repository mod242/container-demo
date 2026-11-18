#!/bin/bash

echo "=========================================="
date
if [[ $ScriptsDir = "" ]]; then
    source ./d_utils.sh
    echo $ScriptsDir
fi
echo "Begin to deploy $PG_IMAGE_NAME:$PG_IMAGE_TAG as $PG_CONTAINER_NAME"
start_time_1=$(date +%s)
filename=$ScriptsDir/"status.log"
source $ScriptsDir/../setProperties.sh

function createPGConfigFolder() {
    echo "Create Postgresql configuration folder..."
    PG_folder_array=($PG_SCRIPT $PG_STORAGE_FOLDER)
    if [ -d "$PG_CONFIGFILES_LOC" ]; then
        echo "Removing existing $PG_CONFIGFILES_LOC folder..."
        rm -fr "$PG_CONFIGFILES_LOC"
    fi

    for folder in ${PG_folder_array[@]}
    do
        echo -e "  - creating $PG_CONFIGFILES_LOC/$folder"
        mkdir -p $PG_CONFIGFILES_LOC/$folder
    done
    # Data directory and tablespace folders are created inside the container (owned by the postgres user)
    chmod -R 777 $PG_CONFIGFILES_LOC
    echo "Created PG config and storage folder successfully"
}

function copyPGConfigFiles() {
    echo "Copy Postgresql configuration files start..."
    cd $ScriptsDir/config-files/postgresql
    if (ls $GCDDB_SCRIPT && ls $OS1DB_SCRIPT && ls $ICNDB_SCRIPT && ls $ENV_LIST && ls $SETUP_DB) >/dev/null 2>&1 ; then
        cp -f $GCDDB_SCRIPT $OS1DB_SCRIPT $ICNDB_SCRIPT $ENV_LIST $SETUP_DB $PG_CONFIGFILES_LOC/$PG_SCRIPT
    else
        echo "You missed some necessary Postgresql configuration files"
        exit_script
    fi
    cd $ScriptsDir
    echo "Copied Postgresql configuration files to $PG_CONFIGFILES_LOC successfully"
}

function deployPGContainer() {
    echo "Start PG docker container now..."
    containerID=`docker ps -a -q --filter name=$PG_CONTAINER_NAME$`
    if [ "$containerID" = "" ]; then
        result=$(docker run -d --name $PG_CONTAINER_NAME --add-host=$HOST_NAME:host-gateway --restart=$PG_RESTART -p $PG_HTTP_PORT:5432 --env-file $PG_CONFIGFILES_LOC/$PG_SCRIPT/$ENV_LIST -e PGDATA=/pgstorage/data -v $PG_CONFIGFILES_LOC/$PG_SCRIPT:/tmp/PG_script -v $PG_CONFIGFILES_LOC/$PG_STORAGE_FOLDER:/pgstorage $PG_REGISTRY_URL/$PG_IMAGE_NAME:$PG_IMAGE_TAG postgres -c max_prepared_transactions=100)
    else
        docker ps -a -q --filter name=$PG_CONTAINER_NAME | grep -q . && docker stop $PG_CONTAINER_NAME && docker rm -fv $PG_CONTAINER_NAME
        result=$(docker run -d --name $PG_CONTAINER_NAME  --add-host=$HOST_NAME:host-gateway --restart=$PG_RESTART -p $PG_HTTP_PORT:5432 --env-file $PG_CONFIGFILES_LOC/$PG_SCRIPT/$ENV_LIST -e PGDATA=/pgstorage/data -v $PG_CONFIGFILES_LOC/$PG_SCRIPT:/tmp/PG_script -v $PG_CONFIGFILES_LOC/$PG_STORAGE_FOLDER:/pgstorage $PG_REGISTRY_URL/$PG_IMAGE_NAME:$PG_IMAGE_TAG postgres -c max_prepared_transactions=100)
    fi
    if [[ "" = $result ]]; then
        echo -e "\033[31mStart $PG_CONTAINER_NAME container failed \033[0m"
        exit
    fi
    echo "Postgresql is starting please wait..."

    i=0
    while(($i<=$TIME_OUT*2))
        do
           # During initialization the server listens on the Unix socket only, so a TCP check
           # succeeds only after the initialization has finished and the final server is up
           docker exec $PG_CONTAINER_NAME pg_isready -q -h 127.0.0.1 -p 5432 >/dev/null 2>&1
            if [ $? -ne 0 ]; then
                let i++
                echo -e " $i. Postgresql docker container still not ready, wait 10 seconds and check again...."
                sleep 10
            else
                echo -e "\033[36mPostgresql docker container started successfully \033[0m"
                break
            fi
        done

        if [[ $i -eq $TIME_OUT*2 ]] ; then
            echo "PG can't start within 30 minutes, exiting now..."
            echo "Please check PG docker container log to check its status."
            exit_script
        fi
}

function createDB() {
  echo "Begin to create the GCDDB,ICNDB,OS1DB database..."
  containerID=`docker ps -a -q --filter name=$PG_CONTAINER_NAME$`
  docker exec -i $PG_CONTAINER_NAME /bin/bash /tmp/PG_script/$SETUP_DB

if [ ! $? -eq 0 ] ; then
    echo -e "\033[31mFailed to create the databases. \033[0m"
    exit_script
fi
}

createPGConfigFolder
copyPGConfigFiles
deployPGContainer
createDB
end_time_1=$(date +%s)
duration_1=$((($end_time_1-$start_time_1)/60))
echo -e "\033[36mDeploy $PG_CONTAINER_NAME container and create database took $duration_1 minute(s) \033[0m"
if [ $? -eq 0 ] ; then
    echo -e "\033[36mFinished deploying $PG_CONTAINER_NAME container and created the databases successfully \033[0m"
    sed -i.bak 's/deployDB: NotCompleted/deployDB: Completed/g' $filename
else
    exit_script
fi
echo "=========================================="
