#/bin/bash


# Change file ownership and folder permissions for non-root execution
# chown 1001:0 /bitnami/postgresql/*.sh
# chown 1001:0 /bitnami/postgresql/*.sql
chmod 755 /bitnami/postgresql/*.sh


# Run the database creation scripts
echo "Begin to create GCDDB database"
/bitnami/postgresql/GCDDB.sh GCDDB
echo "Begin to create OS1DB database"
/bitnami/postgresql/OS1DB.sh OS1DB
echo "Begin to create ICNDB database"
/bitnami/postgresql/ICNDB.sh ICNDB

