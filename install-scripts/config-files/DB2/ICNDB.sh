#!/bin/bash
#
# Licensed Materials - Property of IBM
# 5747-SM3
# (c) Copyright IBM Corp. 2017, 2021  All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
echo "=========================================="
echo "Executing CreateICNDB Commands ..."
date

if [ $# -eq 0 ]; then 
  echo
  echo  Usage: $0 "<database_name>"
  echo
  exit 1
fi

arg1=$1
#len=`echo "${arg1}\c" |wc -c`
len=${#arg1}
if [ $len -gt 8 ]; then
  echo
  echo Invalid DB name "$arg1" : Must be 8 characters or less.
  echo DB creation would fail.  Exiting...
  echo
  exit 1
fi

ICNDB=$1

P8ICNDB="/db2fs/$ICNDB"
mkdir -p $P8ICNDB

echo "Starting DB operations..."
#-- Close any outstanding connection
db2 CONNECT RESET

echo "Creating ICNDB database and tablespaces..."
echo $P8ICNDB
db2 create database $ICNDB AUTOMATIC STORAGE YES ON $P8ICNDB using codeset UTF-8 territory us PAGESIZE 32768
db2 connect to $ICNDB

# Database pre-population not needed for ICN v3.0.5
# db2 -t -f DB2_ONE_SCRIPT.sql

export CUR_COMMIT=ON
db2 update db cfg using cur_commit ON

db2 CONNECT RESET
echo "--------------------"
