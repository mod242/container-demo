#!/bin/bash
#
# Licensed Materials - Property of IBM
# 5747-SM3
# (c) Copyright IBM Corp. 2017, 2021  All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# This file is for debug purpose specially so each script can run separately
#

function exit_script() {
	echo -e "\033[31mSomething wrong, stop and exit now. \033[0m"
     exit 1
}

ScriptsDir=$(cd `dirname $0`; pwd)
chmod +x $ScriptsDir/../setProperties.sh
source $ScriptsDir/../setProperties.sh
