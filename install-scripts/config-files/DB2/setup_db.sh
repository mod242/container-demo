#/bin/bash
#
# Licensed Materials - Property of IBM
# 5747-SM3
# (c) Copyright IBM Corp. 2017, 2021  All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
export CUR_COMMIT=ON
su - db2inst1 -c "db2set DB2_WORKLOAD=FILENET_CM"
echo "set CUR_COMMIT=$CUR_COMMIT"

# Change file ownership and folder permissions for non-root execution
chown db2inst1:db2iadm1 /database/config/db2inst1/*.sh
chown db2inst1:db2iadm1 /database/config/db2inst1/*.sql
chmod 755 /database/config/db2inst1/*.sh
chown -R db2inst1:db2iadm1 /db2fs

# Run the database creation scripts
echo "Begin to create GCDDB database"
su - db2inst1 -c "/database/config/db2inst1/GCDDB.sh GCDDB"
echo "Begin to create OS1DB database"
su - db2inst1 -c "/database/config/db2inst1/OS1DB.sh OS1DB"
echo "Begin to create ICNDB database"
su - db2inst1 -c "/database/config/db2inst1/ICNDB.sh ICNDB"

TIME_OUT=15
i=0
while(($i<=$TIME_OUT*2))
do
  number_of_db=`su - db2inst1 -c "db2 list db directory" | grep "Number of entries in the directory" | awk -F '=' '{print $2}'`
  if [ "$number_of_db"x = ""x -o $number_of_db -lt 3 ]; then
    let i++
    echo -e " $i.DB2 is not ready yet, wait 30 seconds and try again...."
    sleep 30
  else
    echo -e "\033[36mAll databases created successfully \033[0m"
    break
  fi
done
if [[ $i -eq $TIME_OUT*2 ]] ;then
  echo "Database creation did not start within 30 minutes, exiting now..."
  echo "Please check the DB2 container logs for errors."
  exit 1
fi
