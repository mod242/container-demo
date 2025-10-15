#! /bin/bash

if [ $# -eq 0 ]; then
  echo
  echo  Usage: $0 "<database_name>"
  echo
  exit 1
fi

arg1=$1
#len=`echo "${arg1}\c" |wc -c`


P8DBNAME=$1
PGUSER=ceuser

PGPASSWORD=FileNet psql -U postgres <<End_of_file
revoke connect on database $P8DBNAME from public;
grant all privileges on database $P8DBNAME to $PGUSER;
grant connect, temp, create on database $P8DBNAME to $PGUSER;

End_of_file

