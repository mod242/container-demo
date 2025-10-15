#!/bin/bash
#
# Licensed Materials - Property of IBM
# 5747-SM3
# (c) Copyright IBM Corp. 2017, 2021  All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
os_type=`uname -a | awk '{ print $1 }'`

if [[ $ScriptsDir = "" ]]; then
	source ./d_utils.sh
	echo $ScriptsDir
fi

function readFNCSLicense() {
  echo -e "\033[32mYou must review the IBM FileNet Content Manager v5.5.7 License Agreement before continuing\033[0m"
  sleep 3
  less -M -f -c $ScriptsDir/../FNCS_License.txt
}

function readICNLicense() {
  echo -e "\033[32mYou must review the IBM Content Navigator 3.0.10 License Agreement before continuing\033[0m"
  sleep 3
  less -M -f -c $ScriptsDir/../ICN_License.txt
}

function userInput() {
  echo -e "\033[32mDo you accept the IBM license agreement?(y/n)\033[0m"
  read -e choice
  if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
     if [[ $os_type = "Linux" ]]; then
      sed -i 's/LICENSE_ACCEPTED=.*$/LICENSE_ACCEPTED=true/g' ./setProperties.sh
     elif [[ $os_type = "Darwin" ]]; then
      sed -i "" 's/LICENSE_ACCEPTED=.*$/LICENSE_ACCEPTED=true/g' ./setProperties.sh
     else
      echo "\033[31mUnexpected OS type.\033[0m"
      exit
     fi
  elif [[ "$choice" == "n" || "$choice" == "N" ]]; then
    if [[ $os_type = "Linux" ]]; then
      sed -i 's/LICENSE_ACCEPTED=.*$/LICENSE_ACCEPTED=false/g' ./setProperties.sh
    elif [[ $os_type = "Darwin" ]]; then
      sed -i "" 's/LICENSE_ACCEPTED=.*$/LICENSE_ACCEPTED=false/g' ./setProperties.sh
    else
      echo "\033[31mUnexpected OS type.\033[0m"
      exit_script
    fi
    echo -e "\033[31mScript will exit ...\033[0m"
    sleep 2
    exit_script
  else
    echo -e "\033[31mUnexpected input\033[0m"
    userInput
  fi
}


if [[ $LICENSE_ACCEPTED == "false" ]]; then
  readFNCSLicense
  userInput
  readICNLicense
  userInput
elif [[ $LICENSE_ACCEPTED == "true" ]]; then
  echo "You have accepted the IBM software license agreements, continuing to run now."
else
  echo -e "\033[31mIBM software license unexpected error, there is no LICENSE_ACCEPTED variable in setProperties.sh\033[0m"
  exit_script
fi
