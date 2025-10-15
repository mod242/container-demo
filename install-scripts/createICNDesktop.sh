#!/bin/bash
#
# Licensed Materials - Property of IBM
# 5747-SM3
# (c) Copyright IBM Corp. 2017, 2021  All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
echo "=========================================="
date

filename=$ScriptsDir/"status.log"
if [[ $ScriptsDir = "" ]]; then
	source ./d_utils.sh
	echo $ScriptsDir
fi
source $ScriptsDir/../setProperties.sh

echo "Create ICN desktop '$DESKTOP_NAME' with repository '$REPOSITORY_NAME'"
cd $ScriptsDir/../icnadmin/logs
containerReady=false
i=0
while(($i<=$TIME_OUT*2))
do
        isICNOnLine=$(curl -s -I http://$HOST_NAME:$ICN_HTTP_PORT/navigator | grep 302)
        if [[ "$isICNOnLine" != "" ]] ; then
                containerReady=true
		python3 $ScriptsDir/../icnadmin/bin/icndefaultdriver.py --icnURL https://$HOST_NAME:$ICN_HTTPS_PORT/navigator/ \
			--icnAdmin $P8ADMIN_USER --icnPassd $GLOBAL_PASSWORD --ceURL http://$HOST_NAME:$CPE_HTTP_PORT/wsi/FNCEWS40MTOM \
			--objStoreName $P8OS_NAME --featureList browsePane searchPane favorites workPane  --defaultFeature browsePane  \
			--desktopId $DESKTOP_ID --desktopName $DESKTOP_NAME --isDefault true --desktopDesc $DESKTOP_DES --applicationName ECM Containers Demo \
			--osDisplayName $REPOSITORY_NAME --defaultRepo $REPOSITORY_NAME --connectionPoint $PE_CONNPT_NAME:$PE_REGION_NUMBER
		break
        else
                echo "$i. Navigator has not started yet, wait 30 seconds and try again...."
                sleep 30s
                let i++
        fi
done

if [[ "$containerReady" == "false" ]]; then
        icnDeploymentReady=$(curl -s -I http://$HOST_NAME:$ICN_HTTP_PORT/navigator | grep 502 )
        if [[ "$icnDeploymentReady" != "" ]]; then
                echo "Hostname not resolved. Please add your hostname to the /etc/hosts file."
        else
                echo "Content Navigator did not start. Please check the container log file for details."
        fi
        exit_script
fi

if [ $? -eq 0 ] ;then
  echo -e "\033[36mFinished creating ICN desktop '$DESKTOP_NAME' successfully \033[0m"
	sed -i.bak 's/createICNDesktop: NotCompleted/createICNDesktop: Completed/g' $filename
else
        exit_script
fi
echo "=========================================="
