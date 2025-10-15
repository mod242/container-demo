#!/bin/bash
#
# Licensed Materials - Property of IBM
# 5747-SM3
# (c) Copyright IBM Corp. 2017, 2021  All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
os_type=`uname -a | awk '{ print $1 }'`
source $ScriptsDir/../setProperties.sh

function exit_script(){
    exit
}

function mini_requirement(){
	echo -e "\033[32mMinimum system requirements are:
	* 2 CPU cores
	* 8 GB of memory
	* 50 GB disk
	* Ubuntu 18.04 or 20.04
	* Mac OS X 10.15.x 
	* Linux"
	exit_script
}

function get_distro(){
	if [ -f /etc/os-release ]; then
		# freedesktop.org and systemd
		. /etc/os-release
		OS=$NAME
		VER=$VERSION_ID
	elif type lsb_release >/dev/null 2>&1; then
		# linuxbase.org
		OS=$(lsb_release -si)
		VER=$(lsb_release -sr)
	elif [ -f /etc/lsb-release ]; then
		# For some versions of Debian/Ubuntu without lsb_release command
		. /etc/lsb-release
		OS=$DISTRIB_ID
		VER=$DISTRIB_RELEASE
	elif [ -f /etc/debian_version ]; then
		# Older Debian/Ubuntu/etc.
		OS=Debian
		VER=$(cat /etc/debian_version)
	elif [ -f /etc/SuSe-release ]; then
		# Older SuSE/etc.
		...
	elif [ -f /etc/redhat-release ]; then
		# Older Red Hat, CentOS, etc.
		...
	else
		# Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
		OS=$(uname -s)
		VER=$(uname -r)
	fi
}


if [[ "Linux" = "$os_type" ]]; then
		echo "The script are running on a Linux OS, below is the system info:"
		get_distro
		os_version="$OS"
		hostname=`uname -n`
		cpu_info=`cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c`
		number_of_cpu=`grep -c 'model name' /proc/cpuinfo`
		free=`/usr/bin/free -h | /bin/sed 's/Mem:   /Memory:/g' | /usr/bin/awk 'NR < 4'`
		total_memory=`awk '/MemTotal/ {printf( "%d\n", $2 / 1024 )}' /proc/meminfo`
		disk=`/bin/df --sync -h -l -t 'ext4'`
		avail_disk=`/bin/df --sync -BG -l -t 'ext4' | grep dev | awk '{print $4}' | cut -f 1 -d "G"`
		disk_usage_rate=`/bin/df --sync -h -l -t 'ext4' | grep dev | awk '{print $5}' | cut -f 1 -d "%"`
		cpu_load=`/usr/bin/uptime | /bin/sed 's/, /\//g' | /usr/bin/awk '{print $(NF-0)}'`
		/bin/echo "================================================================================"
		/bin/echo "${bold}Host  name:${normal} $hostname"
		/bin/echo "${bold}OS version:${normal} $os_version"
		/bin/echo "${bold}CPU:       ${normal} $cpu_info"
		/bin/echo "--------------------------------------------------------------------------------"
		/bin/echo "$free"
		/bin/echo -e "\r"
		/bin/echo "--------------------------------------------------------------------------------"
		/bin/echo "$disk"
		/bin/echo "================================================================================"
		sed -i 's/OS=.*$/OS=Linux/g' $ScriptsDir/../setProperties.sh

		if [ 2 -gt $number_of_cpu ]; then
		  echo "\033[31mYou need at least 2 CPU cores\033[0m"
		  mini_requirement
		fi

		minimum_disk=50
		if (($avail_disk < $minimum_disk)); then
		  echo "\033[31mThe avail disk of $hostname is $avail_disk GB\033[0m"
		  mini_requirement
		fi

		minimum_total_memory=7
		if (($total_memory < $minimum_total_memory)); then
		  echo -e "\033[31mThe RAM of $hostname is $total_memory GB\033[0m"
		  mini_requirement
		fi

	elif [[ "Darwin" = "$os_type" ]]; then
		echo "The script are running on a Mac OS, below is the system info:"
		os_name=`sw_vers | grep "ProductName" | awk -F ':' '{ print $2 }'`
		os_product_version=`sw_vers | grep "ProductVersion" | awk -F ':' '{ print $2 }' | sed 's/[[:space:]]//g'`
		host_name=`uname -n`
		os_kernel=`uname -v | awk -F ':' '{print $1}'`
		cpu_count=`sysctl -n machdep.cpu.core_count`
		cpu_info=`sysctl -n machdep.cpu.brand_string`
		cpu_load=`/usr/bin/uptime | awk -F 'averages:' '{ print $2 }'`
		disk_info=`df -h`
		avail_disk_space=`df -h | grep "disk1" | awk '{ print $4 }' | head -1 | cut -f 1 -d "G" | sed 's/[[:space:]]//g'`
		memory=`top -l 1 -s 0 | grep PhysMem`
		total_memory=`python ./install-scripts/config-files/Mac/mac_free.py | grep "Real Mem Total" | awk -F ":" '{ print $2 }' | cut -f 1 -d "G" | sed 's/[[:space:]]//g'`
		/bin/echo "================================================================================"
		/bin/echo "${bold}Host  name:${normal} $host_name"
		/bin/echo "${bold}OS version:${normal} $os_name ${normal} $os_product_version"
		/bin/echo "${bold}Kernel:    ${normal} $os_kernel"
		/bin/echo "${bold}CPU:       ${normal} $cpu_count ${normal} $cpu_info"
		/bin/echo "--------------------------------------------------------------------------------"
		/bin/echo "$memory"
		/bin/echo "--------------------------------------------------------------------------------"
		/bin/echo "$disk_info"
		/bin/echo "================================================================================"
		sed -i "" 's/OS=.*$/OS=Mac/g' $ScriptsDir/../setProperties.sh

		if [[ 2 -gt $((cpu_count)) ]]; then
		  echo "\033[31mYou need at least 2 CPU cores\033[0m"
		  mini_requirement
		fi

		minimum_disk=50
		if [[ $((avail_disk_space)) -lt $((minimum_disk)) ]]; then
		  echo "\033[31mThe avail disk of $host_name is $avail_disk_space GB\033[0m"
		  mini_requirement
		fi

		# minimum_total_memory=4
		# if [[ $((total_memory)) -lt $((minimum_total_memory)) ]]; then
		#   echo -e "\033[31mThe RAM of $host_name is $total_memory GB\033[0m"
		#   mini_requirement
		# fi

        minimum_os_product_version=10.15.5
        OLD_IFS="$IFS"
        IFS='.'
        minimum_version_arr=($minimum_os_product_version)
        product_version_arr=($os_product_version)
        IFS=$OLD_IFS
        length=0
        for x in ${product_version_arr[@]}; do
        	let length++
        done

        if [ ${product_version_arr[0]} -lt ${minimum_version_arr[0]} ]; then
        	echo -e "\033[31mYour MacOS production version is $os_product_version\033[0m"
          	mini_requirement
        elif [ ${product_version_arr[0]} -eq ${minimum_version_arr[0]} ]; then
        	if [ ${product_version_arr[1]} -lt ${minimum_version_arr[0]} ]; then
        		echo -e "\033[31mYour MacOS production version is $os_product_version\033[0m"
          		mini_requirement
          	elif [ ${product_version_arr[1]} -eq ${minimum_version_arr[1]} ]; then
          		if [ ${product_version_arr[2]} -lt ${minimum_version_arr[2]} ]; then
          			echo -e "\033[31mYour MacOS production version is $os_product_version\033[0m"
          			mini_requirement
          		fi
          	fi
        fi
	else
		echo "\033[31mNot supported OS, exit now...\033[0m"
		mini_requirement
fi

source $ScriptsDir/../setProperties.sh

###### Validate Docker version #############
# Is docker installed?
if [ -f /usr/bin/docker -o -f /usr/local/bin/docker ]; then
    req_docker_version=$(docker version -f '{{.Client.Version}}'|head -c 2)
    if [ $? -ne 0 ]; then
        echo -e "\033[31mUnable to execute the 'docker version' command.  Is it installed and added to your system PATH?\033[0m"
        echo -e "\033[31mMore information can be found at https://docs.docker.com/install/\033[0m"
        mini_requirement
    else
        if [ $req_docker_version -lt $MIN_DOCKER_VERSION ]; then
            echo -e "\033[31mYour Docker version is $req_docker_version and must be at least ${MIN_DOCKER_VERSION}\033[0m"
            echo -e "\033[31mMore information can be found at https://docs.docker.com/install/\033[0m"
            mini_requirement
		else
            echo -e "\033[36mYour Docker version is $req_docker_version and matches minimum Version ${MIN_DOCKER_VERSION}\033[0m"
        fi
    fi
else
    echo -e "\033[31mDocker not found.  Is it installed and in your system PATH?\033[0m"
    echo -e "\033[31mMore information can be found at https://docs.docker.com/install/\033[0m"
    mini_requirement
fi


###### Check for JDBC Driver when using Postgresql ############
if [[ $DATABASE = "postgresql" ]] || [[ $DATABASE = "POSTGRESQL" ]]; then
	if [ -f "$ScriptsDir/config-files/common/$PGJCC4" ]; then
		echo -e "\033[36mFound JDBC Driver for Postgresql $ScriptsDir/config-files/common/$PGJCC4\033[0m"
	else
		echo -e "\033[36mDownloading JDBC Driver from https://jdbc.postgresql.org/download/$PGJCC4\033[0m"
		wget -q -O $ScriptsDir/config-files/common/$PGJCC4 https://jdbc.postgresql.org/download/$PGJCC4
		if [ $? -ne 0 ]; then
			echo -e "\033[31mDownloading JDBC Driver from https://jdbc.postgresql.org/download/$PGJCC4 failed.\033[0m"
			echo -e "\033[31mPlease download manually and place it in $ScriptsDir/config-files/common/$PGJCC4\033[0m"
			mini_requirement
		fi
	fi
fi

###### Check for Docker-py ############
python3 -c "import sys, pkgutil; sys.exit(0 if pkgutil.find_loader(sys.argv[1]) else 1)" docker
if [ $? -ne 0 ]; then
	echo -e "\033[31mDidn't find docker-py\033[0m"
	echo -e "\033[31mPlease install via pip or your local package manager\033[0m"
	mini_requirement
fi

######### Validate OpenLDAP container image ################
req_openldap_version=$(docker image inspect $LDAP_REGISTRY_URL/$LDAP_IMAGE_NAME:$LDAP_IMAGE_TAG)
if [ $? -ne 0 ]; then
    echo -e "\033[31mOpenLDAP container not found. Pulling the latest image from Docker Hub\033[0m"
    if [[ $REGISTRY_USERNAME != "" ]] && [[ $REGISTRY_PASSWORD != "" ]]; then
		docker login -u $REGISTRY_USERNAME -p $REGISTRY_PASSWORD
	fi
	docker pull $LDAP_REGISTRY_URL/$LDAP_IMAGE_NAME:$LDAP_IMAGE_TAG
    req_openldap_version=$(docker image inspect $LDAP_REGISTRY_URL/$LDAP_IMAGE_NAME:$LDAP_IMAGE_TAG)
    if [ $? -ne 0 ]; then
        echo -e "\033[31mOpenLDAP container not found after pulling. Stopping now. \033[0m"
        mini_requirement
    else
	    echo -e "\033[36mFound correct LDAP container\033[0m"
    fi
else
	echo -e "\033[36mFound correct OpenLDAP container\033[0m"
fi


if [[ $DATABASE = "postgresql" ]] || [[ $DATABASE = "POSTGRESQL" ]]; then
	######### Validate Postgresql container image ################
	req_pg_version=$(docker image inspect $PG_REGISTRY_URL/$PG_IMAGE_NAME:$PG_IMAGE_TAG)
	if [ $? -ne 0 ]; then
		echo -e "\033[31mPostgresql container not found. Pulling the latest image from Docker Hub\033[0m"
		if [[ $REGISTRY_USERNAME != "" ]] && [[ $REGISTRY_PASSWORD != "" ]]; then
			docker login -u $REGISTRY_USERNAME -p $REGISTRY_PASSWORD
		fi
		docker pull $PG_REGISTRY_URL/$PG_IMAGE_NAME:$PG_IMAGE_TAG
		req_db2_version=$(docker image inspect $PG_REGISTRY_URL/$PG_IMAGE_NAME:$PG_IMAGE_TAG)
		if [ $? -ne 0 ]; then
			echo -e "\033[31mPostgresql container not found after pulling. Stopping now. \033[0m"
			mini_requirement
		else
			echo -e "\033[36mFound correct Postgresql container\033[0m"
		fi
	else
		echo -e "\033[36mFound correct Postgresql container\033[0m"
	fi
else
	######### Validate DB2 container image ################
	req_db2_version=$(docker image inspect $DB2_REGISTRY_URL/$DB2_IMAGE_NAME:$DB2_IMAGE_TAG)
	if [ $? -ne 0 ]; then
		echo -e "\033[31mDB2 container not found. Pulling the latest image from Docker Hub\033[0m"
		if [[ $REGISTRY_USERNAME != "" ]] && [[ $REGISTRY_PASSWORD != "" ]]; then
			docker login -u $REGISTRY_USERNAME -p $REGISTRY_PASSWORD
		fi
		docker pull $DB2_REGISTRY_URL/$DB2_IMAGE_NAME:$DB2_IMAGE_TAG
		req_db2_version=$(docker image inspect $DB2_REGISTRY_URL/$DB2_IMAGE_NAME:$DB2_IMAGE_TAG)
		if [ $? -ne 0 ]; then
			echo -e "\033[31mDB2 container not found after pulling. Stopping now. \033[0m"
			mini_requirement
		else
			echo -e "\033[36mFound correct DB2 container\033[0m"
		fi
	else
		echo -e "\033[36mFound correct DB2 container\033[0m"
	fi
fi



