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
echo "Begin to update the configuration files for P8 and ICN"
filename=$ScriptsDir/"status.log"
source $ScriptsDir/../setProperties.sh

function modifyHostName(){
	hostName=$(hostname -f)
	if [[ "$OS" = "Mac" ]]; then
		sed -i "" -e "s/^HOST_NAME=.*/HOST_NAME=$hostName/g" $ScriptsDir/../setProperties.sh
	elif [[ "$OS" = "Linux" ]]; then
		sed -i -e "s/^HOST_NAME=.*/HOST_NAME=$hostName/g" $ScriptsDir/../setProperties.sh
	fi
	echo "Begin to set hostname to $hostName:"
	echo -e "  - Updated hostname for setProperties.sh"

	configuration_files=($ScriptsDir/config-files/CPE/$FNGCDDS \
		$ScriptsDir/config-files/CPE/$FNDOSDS \
		$ScriptsDir/config-files/common/$LDAP \
		$ScriptsDir/config-files/ICN/$ICNDS	)
	for a_file in ${configuration_files[@]}
	do
		if [[ -f $ScriptsDir/config-files/CPE/$FNGCDDS ]];  then
			if [ "$OS" = "Mac" ]; then
				sed -i "" -e "s/localhost/$hostName/g" $a_file
			elif [ "$OS" = "Linux" ]; then
				sed -i -e "s/localhost/$hostName/g" $a_file
			fi
			echo -e "  - Updated hostname for $a_file"
		else
			echo -e "\033[31m$0Cannot find $a_file, please make sure you have downloaded the complete Container PIT archive. \033[0m"
			exit_script
		fi
	done
}

function reCreateCPEPropFile(){
	cd $ScriptsDir/config-files/CPE
	docker exec -i $JDK_CONTAINER_NAME java -Dfile.encoding=utf-8 -jar $ScriptsDir/config-files/CPE/BootstrapConfig.jar -s FNGCDDS -x FNGCDDSXA -u P8Admin -p $GLOBAL_PASSWORD -e $ScriptsDir/config-files/CPE/BootstrapConfigProps.jar -b 256 -c AES -k -o true
	if [ $? -eq 0 ] ;then
        echo "done"
	else
        echo "Cannot re-generate props.jar file, stopping now...."
        exit_script
	fi

	docker exec -i $JDK_CONTAINER_NAME jar xvf $ScriptsDir/config-files/CPE/BootstrapConfigProps.jar APP-INF/lib/props.jar
	rm -f $ScriptsDir/config-files/CPE/$PROPS
	docker cp ibmjdk:/APP-INF/lib/props.jar $ScriptsDir/config-files/CPE/$PROPS
	if [ -f $ScriptsDir/config-files/CPE/$PROPS ] && [ $? -eq 0 ];  then
   	echo "Recreated the props.jar file"
  	rm -fr APP-INF
	else
		echo "Failed to replace the props.jar file, stopping now..."
		exit_script
	fi
}

function modifyLdapConfigFile(){
	if [ -f $ScriptsDir/config-files/common/$LDAP ];  then
		if [[ "Linux" = "$OS" ]]; then
			sed -i -e "s/FileNet/$GLOBAL_PASSWORD/g" $ScriptsDir/config-files/common/$LDAP
		elif [[ "Mac" = "$OS" ]]; then
			sed -i "" -e "s/FileNet/$GLOBAL_PASSWORD/g" $ScriptsDir/config-files/common/$LDAP
		fi
		echo "Updated ldap password in $ScriptsDir/config-files/common/$LDAP"
	else
		echo "Cannot find $ScriptsDir/config-files/common/$LDAP!"
		exit_script
	fi
}

function modifyDB2PWD() {
	db2_files=( $ScriptsDir/config-files/DB2/$ENV_LIST \
		$ScriptsDir/config-files/CPE/$FNGCDDS \
		$ScriptsDir/config-files/CPE/$FNDOSDS \
		$ScriptsDir/config-files/ICN/$ICNDS )

	for db2_file in ${db2_files[@]}
	do
		if [ -f $db2_file ];  then
			if [ "$OS" = "Mac" ]; then
				sed -i "" -e "s/FileNet/$GLOBAL_PASSWORD/g" $db2_file
			elif [ "$OS" = "Linux" ]; then
				sed -i -e "s/FileNet/$GLOBAL_PASSWORD/g" $db2_file
			fi
			echo -e "  - Updated database password for $db2_file"
		else
			echo -e "\033[31m$0 Cannot find $db2_file, please make sure you have downloaded the complete Container PIT archive \033[0m"
			exit_script
		fi
	done
}


function modifyPGPWD() {
	pg_files=( $ScriptsDir/config-files/postgresql/$ENV_LIST \
	    $ScriptsDir/config-files/postgresql/$GCDDB_SCRIPT \
		$ScriptsDir/config-files/postgresql/$OS1DB_SCRIPT \
		$ScriptsDir/config-files/postgresql/$ICNDB_SCRIPT \
		$ScriptsDir/config-files/CPE/$FNGCDDS \
		$ScriptsDir/config-files/CPE/$FNDOSDS \
		$ScriptsDir/config-files/ICN/$ICNDS )

	for pg_file in ${pg_files[@]}
	do
		if [ -f $pg_file ];  then
			if [ "$OS" = "Mac" ]; then
				sed -i "" -e "s/FileNet/$GLOBAL_PASSWORD/g" $pg_file
			elif [ "$OS" = "Linux" ]; then
				sed -i -e "s/FileNet/$GLOBAL_PASSWORD/g" $pg_file
			fi
			echo -e "  - Updated database password for $pg_file"
		else
			echo -e "\033[31m$0 Cannot find $pg_file, please make sure you have downloaded the complete Container PIT archive \033[0m"
			exit_script
		fi
	done
}

function modifyDB2Port() {
	db2_files=( $ScriptsDir/config-files/CPE/$FNGCDDS \
		$ScriptsDir/config-files/CPE/$FNDOSDS \
		$ScriptsDir/config-files/ICN/$ICNDS )

	for db2_file in ${db2_files[@]}
	do
		if [ -f $db2_file ];  then
			if [ "$OS" = "Mac" ]; then
				sed -i "" -e "s/50000/$DB2_HTTP_PORT/g" $db2_file
			elif [ "$OS" = "Linux" ]; then
				sed -i -e "s/50000/$DB2_HTTP_PORT/g" $db2_file
			fi
			echo -e "  - Updated database port for $db2_file"
		else
			echo -e "\033[31m$0 Cannot find $db2_file, please make sure you have downloaded the complete Container PIT archive \033[0m"
			exit_script
		fi
	done
}

function modifyPGPort() {
	pg_files=( $ScriptsDir/config-files/CPE/$FNGCDDS \
		$ScriptsDir/config-files/CPE/$FNDOSDS \
		$ScriptsDir/config-files/ICN/$ICNDS )

	for pg_file in ${pg_files[@]}
	do
		if [ -f $pg_file ];  then
			if [ "$OS" = "Mac" ]; then
				sed -i "" -e "s/5432/$PG_HTTP_PORT/g" $pg_file
			elif [ "$OS" = "Linux" ]; then
				sed -i -e "s/5432/$PG_HTTP_PORT/g" $pg_file
			fi
			echo -e "  - Updated database port for $pg_file"
		else
			echo -e "\033[31m$0 Cannot find $pg_file, please make sure you have downloaded the complete Container PIT archive \033[0m"
			exit_script
		fi
	done
}

function modifyMountLocation(){
	home=$(cd ~; pwd)
	needUpdate=$(cat $ScriptsDir/../setProperties.sh | grep "CPE_CONFIGFILES_LOC=.*" | grep $home)
	if [ "$needUpdate" = "" ]; then
		echo "Updated volume folder location to under $home"
		if [ "$OS" = "Mac" ]; then
			sed -i "" "s#CPE_CONFIGFILES_LOC=.*#CPE_CONFIGFILES_LOC=$home/cpit_data/cpe_data#g"  $ScriptsDir/../setProperties.sh
			sed -i "" "s#ICN_CONFIGFILES_LOC=.*#ICN_CONFIGFILES_LOC=$home/cpit_data/icn_data#g"  $ScriptsDir/../setProperties.sh
			sed -i "" "s#DB2_CONFIGFILES_LOC=.*#DB2_CONFIGFILES_LOC=$home/cpit_data/db2_data#g"  $ScriptsDir/../setProperties.sh
			sed -i "" "s#PG_CONFIGFILES_LOC=.*#PG_CONFIGFILES_LOC=$home/cpit_data/pg_data#g"  $ScriptsDir/../setProperties.sh

		elif [ "$OS" = "Linux" ]; then
			sed -i "s#CPE_CONFIGFILES_LOC=.*#CPE_CONFIGFILES_LOC=$home/cpit_data/cpe_data#g"  $ScriptsDir/../setProperties.sh
			sed -i "s#ICN_CONFIGFILES_LOC=.*#ICN_CONFIGFILES_LOC=$home/cpit_data/icn_data#g"  $ScriptsDir/../setProperties.sh
			sed -i "s#DB2_CONFIGFILES_LOC=.*#DB2_CONFIGFILES_LOC=$home/cpit_data/db2_data#g"  $ScriptsDir/../setProperties.sh
			sed -i "s#PG_CONFIGFILES_LOC=.*#ÜG_CONFIGFILES_LOC=$home/cpit_data/pg_data#g"  $ScriptsDir/../setProperties.sh

		fi
	else
		echo "No need to update the volume folder location."
	fi
	echo -e "  - CPE_CONFIGFILES_LOC=$home/cpit_data/cpe_data"
	echo -e "  - ICN_CONFIGFILES_LOC=$home/cpit_data/icn_data"
	echo -e "  - DB2_CONFIGFILES_LOC=$home/cpit_data/db2_data"
	echo -e "  - PG_CONFIGFILES_LOC=$home/cpit_data/pg_data"

}

modifyHostName
# Deprecated in CPE v5.5.x
# reCreateCPEPropFile
modifyLdapConfigFile
modifyDB2PWD
modifyDB2Port
modifyPGPWD
modifyPGPort
modifyMountLocation

if [ $? -eq 0 ] ;then
    echo -e "\033[36mFinished updating all the configuration files, now we are ready to go! \033[0m"
     sed -i.bak 's/updateConfigFiles: NotCompleted/updateConfigFiles: Completed/g' $filename
else
    exit_script
fi
echo "=========================================="
