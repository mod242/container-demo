#!/bin/bash
# Runs inside the postgres container (as root via docker exec)

SCRIPT_DIR=/tmp/PG_script

# Tablespace folders for the workflow system, must be owned by the postgres user
mkdir -p /pgstorage/ts/vwdata /pgstorage/ts/vwindex /pgstorage/ts/vwblob
chown -R postgres:postgres /pgstorage/ts
chmod 700 /pgstorage/ts/vwdata /pgstorage/ts/vwindex /pgstorage/ts/vwblob

# Run the database creation scripts
echo "Begin to create GCDDB database"
/bin/bash $SCRIPT_DIR/GCDDB.sh GCDDB || exit 1
echo "Begin to create OS1DB database"
/bin/bash $SCRIPT_DIR/OS1DB.sh OS1DB || exit 1
echo "Begin to create ICNDB database"
/bin/bash $SCRIPT_DIR/ICNDB.sh ICNDB || exit 1
