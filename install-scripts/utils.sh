#!/bin/bash
#
# Licensed Materials - Property of IBM
# 5747-SM3
# (c) Copyright IBM Corp. 2017, 2021  All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
log="cpit_log.log"
fsize=2000000
if [ ! -e log.fifo ]; then
  mkfifo log.fifo
else
	rm -f log.fifo
	mkfifo log.fifo
fi

cat log.fifo | tee -a $log &
exec 2>>log.fifo
exec 1>>log.fifo

function cpitLog()
{
  if [ ! -e "$log" ]; then
    touch $log
  fi
  local curtime
  curtime=`date +"%Y%m%d%H%M%S"`
  local cursize
  cursize=`cat $log | wc -c`

  if [ $fsize -lt $cursize ]; then
    mv $log $curtime".out"
    touch $log
  fi
  echo "$curtime $*" >> $log
}

function exit_script(){
	  echo -e "\033[31mSomething unexpected happen, stop and exit now. \033[0m"
     exit 1
}

cpitLog
