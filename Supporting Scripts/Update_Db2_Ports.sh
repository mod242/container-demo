#!/bin/bash
#
# Licensed Materials - Property of IBM
# 5747-SM3
# (c) Copyright IBM Corp. 2017, 2021  All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#

# Update Db2 port settings to the initial values 
for port in DB2_db2inst1 DB2_db2inst1_1 DB2_db2inst1_2 DB2_db2inst1_3 DB2_db2inst1_4 DB2_db2inst1_END db2c_db2inst1;
  do 
  case "$port" in
    DB2_db2inst1) echo "Modifying port: " $port
                  old_port=60000
                  new_port=20016
                  ;;
    DB2_db2inst1_1) echo "Modifying port: " $port
                    old_port=60001
                    new_port=20017
                    ;;
    DB2_db2inst1_2) echo "Modifying port: " $port
                    old_port=60002
                    new_port=20018
                    ;;
    DB2_db2inst1_3) echo "Modifying port: " $port
                    old_port=60003
                    new_port=20019
                    ;;
    DB2_db2inst1_4) echo "Modifying port: " $port
                    old_port=60004
                    new_port=20020
                    ;;
    DB2_db2inst1_END) echo "Modifying port: " $port
                      old_port=60005
                      new_port=20021
                      ;;    
    db2c_db2inst1) echo "Modifying port: " $port
                   old_port=50000
                   new_port=25010
                   ;;       
  esac
  echo "Current value: " $old_port
  echo "Updated value: " $new_port
  docker exec -it db2 bash -c "sed -i.bak 's/$old_port/$new_port/g' /etc/services"
  echo "--------------------------------------------------------------"
done

# Stop the Db2 server
echo "Stopping Db2 server......."
docker exec -it db2 bash -c "su - db2inst1 -c db2stop"


# Start the Db2 server
echo "Starting Db2 server........"
docker exec -it db2 bash -c "su - db2inst1 -c db2start"