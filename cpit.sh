#!/bin/bash
#
# Licensed Materials - Property of IBM
# 5747-SM3
# (c) Copyright IBM Corp. 2017, 2021  All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#

start_time_0=$(date +%s)
basepath=$(cd `dirname $0`; pwd)
ScriptsDir="$basepath/install-scripts"
chmod -R +x $ScriptsDir
chmod +x ./setProperties.sh
source ./setProperties.sh

# create status.log keeps track of the script completion or non-completion
filename=$ScriptsDir/"status.log"
if [ ! -f $filename ]
then
    touch $filename
    echo "installDockerEnv: NotCompleted" >> $filename
    echo "downloadImages: NotCompleted" >> $filename
    echo "deployJDK: NotCompleted" >> $filename
    echo "updateConfigFiles: NotCompleted" >> $filename
    echo "deployLDAP: NotCompleted" >> $filename
    echo "deployDB: NotCompleted" >> $filename
    echo "deployCPE: NotCompleted" >> $filename
    echo "createP8Domain: NotCompleted" >> $filename
    echo "createP8os: NotCompleted" >> $filename
    echo "createWF: NotCompleted" >> $filename
    echo "deployICN: NotCompleted" >> $filename
    echo "createICNDesktop: NotCompleted" >> $filename
else
    echo "Status file found"
fi

source $ScriptsDir/utils.sh
source $ScriptsDir/getLicenseApproval.sh
source $ScriptsDir/gatherHostInfo.sh
source $ScriptsDir/getCredential.sh

# Check status of script and only execute if it is NotCompleted

# if grep -q "installDockerEnv: Completed" $filename; then
#     echo "Skipping installDockerEnv.sh, as it was completed during previous execution!"
# else
#     echo "installDockerEnv.sh was not run before, running now!"
#     source $ScriptsDir/installDockerEnv.sh
# fi

if grep -q "downloadImages: Completed" $filename; then
    echo "Skipping downloadImages.sh, as it was completed during previous execution!"
else
    echo "downloadImages.sh was not run before, running now!"
    source $ScriptsDir/downloadImages.sh
fi

# Copy the CPE client libraries (Jace.jar, pe*.jar) matching the CPE image into install-scripts/CPELibs
source $ScriptsDir/extractCPELibs.sh

if grep -q "deployJDK: Completed" $filename; then
    echo "Skipping deployJDK.sh, as it was completed during previous execution!"
else
    echo "deployJDK.sh was not run before, running now!"
    source $ScriptsDir/deployJDK.sh
fi

if grep -q "updateConfigFiles: Completed" $filename; then
    echo "Skipping updateConfigFiles.sh, as it was completed during previous execution!"
else
    echo "updateConfigFiles.sh was not run before, running now!"
    source $ScriptsDir/updateConfigFiles.sh
fi

if grep -q "deployLDAP: Completed" $filename; then
    echo "Skipping deployLDAP.sh, as it was completed during previous execution!"
else
    echo "deployLDAP.sh was not run before, running now!"
    source $ScriptsDir/deployLDAP.sh
fi

if [[ $DATABASE = "postgresql" ]] || [[ $DATABASE = "POSTGRESQL" ]]; then
    if grep -q "deployDB: Completed" $filename; then
        echo "Skipping deployPG.sh, as it was completed during previous execution!"
    else
        echo "deployPG.sh was not run before, running now!"
        source $ScriptsDir/deployPG.sh
    fi
else
    if grep -q "deployDB: Completed" $filename; then
        echo "Skipping deployDB2.sh, as it was completed during previous execution!"
    else
        echo "deployDB2.sh was not run before, running now!"
        source $ScriptsDir/deployDB2.sh
    fi
fi



if grep -q "deployCPE: Completed" $filename; then
    echo "Skipping deployCPE.sh, as it was completed during previous execution!"
else
    echo "deployCPE.sh was not run before, running now!"
    source $ScriptsDir/deployCPE.sh
fi

if grep -q "createP8Domain: Completed" $filename; then
    echo "Skipping createP8Domain.sh, as it was completed during previous execution!"
else
    echo "createP8Domain.sh was not run before, running now!"
    source $ScriptsDir/createP8Domain.sh
fi

if grep -q "createP8os: Completed" $filename; then
    echo "Skipping createP8os.sh, as it was completed during previous execution!"
else
    echo "createP8os.sh was not run before, running now!"
    source $ScriptsDir/createP8os.sh
fi

if grep -q "createWF: Completed" $filename; then
    echo "Skipping createWF.sh, as it was completed during previous execution!"
else
    echo "createWF.sh was not run before, running now!"
    source $ScriptsDir/createWF.sh
fi

if grep -q "deployICN: Completed" $filename; then
    echo "Skipping deployICN.sh, as it was completed during previous execution!"
else
    echo "deployICN.sh was not run before, running now!"
    source $ScriptsDir/deployICN.sh
fi

if grep -q "createICNDesktop: Completed" $filename; then
    echo "Skipping createICNDesktop.sh, as it was completed during previous execution!"
else
    echo "createICNDesktop.sh was not run before, running now!"
    source $ScriptsDir/createICNDesktop.sh
fi

source $ScriptsDir/endingActions.sh

end_time_0=$(date +%s)
duration_0=$((($end_time_0-$start_time_0)/60))
echo "This execution took $duration_0 minutes"
