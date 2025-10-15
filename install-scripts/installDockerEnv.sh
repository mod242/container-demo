#!/bin/bash
#
# Licensed Materials - Property of IBM
# 5747-SM3
# (c) Copyright IBM Corp. 2017, 2021  All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
echo "=========================================="
echo "Begin installing docker libraries"
# create status.log keeps track of the script completion or non-completion

date
if [[ $ScriptsDir = "" ]]; then
  source ./d_utils.sh
  echo $ScriptsDir
fi
#create a tracking file called installstatus.log keeps track of installed before or not
filename=$ScriptsDir/"status.log"
source $ScriptsDir/../setProperties.sh

trackfilename=$ScriptsDir/"installstatus.log"

function installCommon() {
	apt-get update
	apt-get install python3-pip -y
	apt-get install ldap-utils -y
    python3 -m pip install -U pip
}

function installDockerLinux () {
    sudo apt-get remove docker docker-engine docker.io containerd runc -y

    sudo apt-get update -y

    sudo apt-get install \
        apt-transport-https \
        ca-certificates \
        curl \
	    gnupg-agent \
        software-properties-common -y

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    sudo apt-key fingerprint 0EBFCD88

    sudo add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) \
        stable"

    sudo apt-get update -y

    sudo apt-get install docker-ce docker-ce-cli containerd.io -y

    sudo apt-get install docker-ce=5:20.10.2~3-0~ubuntu-focal docker-ce-cli=5:20.10.2~3-0~ubuntu-focal -y
}

function installIBMJDK() {
        JAVA_VERSION=1.8.0_sr6fp20
        apt-get install -y --no-install-recommends wget ca-certificates && rm -rf /var/lib/apt/lists/*
        ARCH="$(dpkg --print-architecture)";
          case "${ARCH}" in
            amd64|x86_64)
               YML_FILE='sdk/linux/x86_64/index.yml'
               ;;
            i386)
               YML_FILE='sdk/linux/i386/index.yml'
               ;;
            ppc64el|ppc64le)
               YML_FILE='sdk/linux/ppc64le/index.yml'
               ;;
            s390)
               YML_FILE='sdk/linux/s390/index.yml'
               ;;
            s390x)
               YML_FILE='sdk/linux/s390x/index.yml'
               ;;
            *)
            echo "Unsupported arch: ${ARCH}"
            exit 1
            ;;
          esac
          BASE_URL="https://public.dhe.ibm.com/ibmdl/export/pub/systems/cloud/runtimes/java/meta/"
          wget -q -U UA_IBM_JAVA_Docker -O /tmp/index.yml ${BASE_URL}/${YML_FILE}
          JAVA_URL=$(cat /tmp/index.yml | sed -n '/'${JAVA_VERSION}'/{n;p}' | sed -n 's/\s*uri:\s//p' | tr -d '\r');
          ESUM=$(cat /tmp/index.yml | sed -n '/'$JAVA_VERSION'/,/sha256sum/p' | sed -n 's/\s*sha256sum:\s//p' | tr -d  '\r' )
          echo "Downloading $JAVA_VERSION installer..."
          wget -q -U UA_IBM_JAVA_Docker -O /tmp/ibm-java.bin ${JAVA_URL}
          echo "${ESUM}  /tmp/ibm-java.bin" | sha256sum -c -
          echo "INSTALLER_UI=silent" > /tmp/response.properties
          echo "USER_INSTALL_DIR=/opt/ibm/java" >> /tmp/response.properties
          echo "LICENSE_ACCEPTED=TRUE" >> /tmp/response.properties
          mkdir -p /opt/ibm
          chmod +x /tmp/ibm-java.bin
          /tmp/ibm-java.bin -i silent -f /tmp/response.properties
          rm -f /tmp/response.properties
          rm -f /tmp/index.yml
          rm -f /tmp/ibm-java.bin
          cd /opt/ibm/java/jre/lib
          rm -rf icc
		  cd $scriptPath

        if [[ "$(grep 'JAVA_HOME=' /etc/profile)" != "" ]]; then
            echo "JAVA_HOME already exist in bash_profile"
        else
            echo "Set JAVA_HOME=/opt/ibm/java/jre in /etc/profile"
            echo "export JAVA_HOME=/opt/ibm/java/jre" >> /etc/profile
        fi
          if [[ "$(grep 'PATH=' /etc/profile)" != "" ]]; then
            if [[ "$(grep 'PATH=' /etc/profile | grep 'java')" != "" ]]; then
       			echo "JAVA path already exist in system PATH."
       		else
                echo "Adding java path to PATH value in /etc/profile"
                sed -i "s#export PATH=.*#export PATH=/opt/ibm/java/bin:$PATH#g" /etc/profile
        	fi
    else
        echo "Set path value in /etc/profile"
        echo "export PATH=/opt/ibm/java/bin:$PATH" >> /etc/profile
    fi
    source /etc/profile
    echo "Set IBM java environment successfully."
}

# Docker SDK for Python - required by the createICNDesktop scripts
function installDockerPy() {
	export LC_ALL=C
	if [[ "Linux"x = "$OS"x ]]; then
		pip install docker-py
	elif [[ "Mac"x = "$OS"x ]]; then
	    easy_install pip
	    python3 -m pip install docker-py
	fi
}

#download and install IBM Cloud CLI
function installCLI(){
	if [[ "Linux"x = "$OS"x ]]; then
		curl -fsSL https://clis.ng.bluemix.net/install/linux | sh
	elif [[ "Mac"x = "$OS"x ]]; then
		curl -fsSL https://clis.ng.bluemix.net/install/osx | sh
	fi
	bx plugin install container-registry -r Bluemix -f
	bx plugin install container-service -r Bluemix -f
}

function installDockerForMac() {
	if [[ -d /Applications/Docker.app ]]; then
		echo "Docker already installed but not started, starting docker now...."
		open /Applications/Docker.app
	else
		echo "Downloading Docker..."
		curl -O https://download.docker.com/mac/stable/Docker.dmg
		VOLUME=`hdiutil attach ./Docker.dmg | grep Volumes | awk '{ print $3 }'`
		cp -rf $VOLUME/*.app /Applications
		hdiutil detach $VOLUME
		open /Applications/Docker.app
	fi

	i=0
	while (($i<=$TIME_OUT*2))
	do
		docker ps >/dev/null 2>&1
		if [ ! $? -eq 0 ] ;then
			echo "$i. Please click on the dialog to enable Docker for Mac."
			sleep 30s
			let i++
		else
			echo -e "\033[36mDocker started. \033[0m"
			break
		fi
	done

	if [[ $i -eq $TIME_OUT*2 ]] ;then
		echo -e "\033[31mPlease follow the dialog to launch docker and relaunch cpit.sh again.\033[0m"
		exit_script
	fi
}

function checkDockerStatus() {
  i=0
  while(($i<=$TIME_OUT*2))
  do
    docker ps >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
      echo "Docker is running."
      break
    else
      echo "$i. Docker is not ready, wait 10 seconds and retry again...."
      sleep 10s
      let i++
    fi
  done
  if [[ $i -eq $TIME_OUT*2 ]] ;then
  echo -e "\033[31mDocker can't start in 5 minutes, something could be wrong, exit now... \033[0m"
  echo -e "\033[31m1. You can manual start docker application and make sure it is running.\033[0m"
  echo -e "\033[31m2. Rerun script cpit.sh again.\033[0m"
  exit_script
fi
}

function checkDockerMemory() {
	i=0
	while (($i<=$TIME_OUT*2))
	do
		docker ps >/dev/null 2>&1
		if [[ $? -eq 0 ]]; then
			dockerInfo=$(docker info | grep Memory | sed s/[[:space:]]//g)
			memory_t=${dockerInfo#*:}
			memory=${memory_t%GiB*}
			echo "Current allocated memory for Docker is $memory GB."
			miniSize=3.5
			a=$(awk -v t1=$memory -v t2=$miniSize 'BEGIN{print(t1>t2)?'0':'1'}')

			if [[ "$a" = 0 ]] ;then
				echo "Your memory setting satisfied the requirement."
				break
			else
				echo "You need to adjust the allocated memory to Docker to 4 GB."
				echo "Pls click the Docker icon -> Preference -> Advanced to change it."
				echo "$i. now sleep 30 seconds and recheck again...."
				sleep 30s
				let i++
			fi
		else
	      echo "$i. Docker is not ready, maybe restarting wait 30 seconds and recheck again...."
	     sleep 30s
	      let i++
		fi
	done
	if [[ $i -eq $TIME_OUT*2 ]] ;then
		echo -e "\033[31mPls adjust the allocated memory to Docker to 4 GB and relaunch cpit.sh again.\033[0m"
		exit_script
	fi
}


if [[ "Linux"x = "$OS"x ]]; then
	installCommon
	if [ ! $? -eq 0 ] ;then
		echo "Retry installation again"
		apt-get -f install -y && dpkg --configure -a && apt-get update && apt-get clean
		installCommon
		if [ ! $? -eq 0 ] ;then
			echo "Failed on application installation, exit now."
			exit_script
		fi
	fi
	elif [[ "Mac"x = "$OS"x ]]; then
		docker ps >/dev/null 2>&1
		if [[ $? -eq 0 ]]; then
			echo "Docker already installed and running..."
			checkDockerStatus
			checkDockerMemory
		else
			if [[ -d /Applications/Docker.app ]]; then
				echo "Docker already installed, but it is not started, start docker now..."
				open /Applications/Docker.app
				checkDockerStatus
				checkDockerMemory
			else
				echo "Docker not installed. Download and install before launching this tool"
				exit_script
			fi
		fi
else
	echo -e "\033[31m$0Not a supported OS type, script will now exit...\033[0m"
	sleep 3
	exit_script
fi

installDockerPy

if [[ $GET_IMAGE_FROM_BLUEMIX = "true" ]] || [[ $GET_IMAGE_FROM_BLUEMIX = "yes" ]]; then
	installCLI
fi

if [ $? -eq 0 ] ;then
    echo -e "\033[36mFinished installing all required libraries\033[0m"
	# change the status of the task to Completed
	sed -i.bak 's/installDockerEnv: NotCompleted/installDockerEnv: Completed/g' $filename
else
    exit_script
fi
echo "=========================================="
