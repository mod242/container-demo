#! /bin/bash

if [ $# -eq 0 ]; then
  echo
  echo  Usage: $0 "<database_name>"
  echo
  exit 1
fi


P8DBNAME=$1
PGUSER=ceuser

PGPASSWORD=FileNet psql -U postgres <<End_of_file
create database $P8DBNAME owner $PGUSER template template0 encoding UTF8;
revoke connect on database $P8DBNAME from public;
grant all privileges on database $P8DBNAME to $PGUSER;
grant connect, temp, create on database $P8DBNAME to $PGUSER;
CREATE TABLESPACE vwdata_ts OWNER ceuser LOCATION '/bitnami/postgresql/ts/vwdata';
CREATE TABLESPACE vwindex_ts OWNER ceuser LOCATION '/bitnami/postgresql/ts/vwindex';
CREATE TABLESPACE vwblob_ts OWNER ceuser LOCATION '/bitnami/postgresql/ts/vwblob';

End_of_file

