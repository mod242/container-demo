#########################################################################
# *************** REQUIRED section ****************                     #
# Set / modify the parameters in this section before launching the tool #
#########################################################################

# This will be the password for all LDAP and DB2 users
GLOBAL_PASSWORD=FileNet

# Database Type db2 or postgresql
DATABASE=postgresql

# License review
LICENSE_ACCEPTED=false

# User and Group Ids for running the containers (Should match your local user to avoid Permission Problems
U_UID=1000
G_GID=1000

# Docker store credentials (can be left empty, if you don't want to use your Docker User)
REGISTRY_USERNAME=
REGISTRY_PASSWORD=


# Should Images for CPE, ICN be loaded from remote Registry
GET_IMAGE_FROM_REGISTRY=true

# IBM Container Registry credentials (only necessarry if GET_IMAGE_FROM_REGISTRY is true)
CP_USERNAME=cp
CP_PASSWORD=xxxxxxxxx
CP_REGISTRY_URL=cp.icr.io


# ECM containers downloaded from IBM Passport Advantage (only necessarry if GET_IMAGE_FROM_REGISTRY is false)
# Images download location
DOWNLOAD_LOCATION=/home/user/Downloads
# CPE Container image file name
CPE_IMAGE_FILE=IFCPE_5.7.0_LNX_ML.tar.gz 
# Content Navigator image file name
ICN_IMAGE_FILE=ICN_3.2.0_LNX_ML.tar 


# CPE Container Tags
CPE_REGISTRY_URL=cp/cp4a/fncm
CPE_IMAGE_NAME=cpe
CPE_IMAGE_TAG=ga-570-p8cpe-if001

# ICN Container Tags
ICN_REGISTRY_URL=cp/cp4a/ban
ICN_IMAGE_NAME=navigator
ICN_IMAGE_TAG=ga-320-icn-if001

# Downloaded DB2 container info
DB2_REGISTRY_URL=ibmcom
DB2_IMAGE_NAME=db2
DB2_IMAGE_TAG=11.5.5.1

# Downloaded Postgresql container info
PG_REGISTRY_URL=bitnamilegacy
PG_IMAGE_NAME=postgresql
PG_IMAGE_TAG=17.0.0


# Downloaded OpenLDAP container info
LDAP_REGISTRY_URL=osixia
LDAP_IMAGE_NAME=openldap
LDAP_IMAGE_TAG=latest

# CPE Domain and Object Store names
P8DOMAIN_NAME=P8Domain
P8OS_NAME=P8ObjectStore

# ICN Repository and Desktop parameters
REPOSITORY_NAME=P8Repository
DESKTOP_NAME=ECM
DESKTOP_ID=ecm
DESKTOP_DES="This is a Demo desktop"

#######################################################################
# --------------- Optional section -----------------                  #
# Do not change the parameter values in this section unless necessary #
#######################################################################

# Temporary folder to extract the downloaded ECM container images
TEMP_LOCATION=/tmp/cpit_ppa

# Operating system - will be set automatically at runtime
OS=Linux
# Host name - will be set automatically at runtime
HOST_NAME=yourhost

# Minimum supported docker version
MIN_DOCKER_VERSION=20

# Container startup timeout - minutes
TIME_OUT=15

# CPE container mount volumes
CPE_CONFIGFILES_LOC=/home/user/cpit_data/cpe_data
CPE_FILENET_FOLDER=FileNet
CPE_LOGS_FOLDER=logs
CPE_ASA_FOLDER=asa
CPE_TEXTEXT_FOLDER=textext
CPE_ICMRULES_FOLDER=icmrules
CPE_BOOTSTRAP_FOLDER=bootstrap
CPE_OVERRIDES_FOLDER=configDropins/overrides

# ICN container mount volumes
ICN_CONFIGFILES_LOC=/home/user/cpit_data/icn_data
ICN_VIEWERLOG_FOLDER=viewerlog
ICN_VIEWERCACHE_FOLDER=viewercache
ICN_PLUGINS_FOLDER=plugins
ICN_ASPERA_FOLDER=Aspera
ICN_LOGS_FOLDER=logs
ICN_OVERRIDES_FOLDER=configDropins/overrides

# Postgres container mount volumes
PG_CONFIGFILES_LOC=/home/user/cpit_data/pg_data
PG_SCRIPT=pgscript
PG_STORAGE_FOLDER=storage
PGJCC4=postgresql-42.7.2.jar
PGJCCDRIVER=PostgreSQLDriver.xml

# DB2 container mount volumes
DB2_CONFIGFILES_LOC=/home/user/cpit_data/db2_data
DB2_SCRIPT=db2script
DB2_STORAGE_FOLDER=storage

# Common config files
DB2JCC_LICENSE_CU=db2jcc_license_cu.jar
DB2JCC4=db2jcc4.jar
DB2JCCDRIVER=DB2JCCDriver.xml
LDAP=ldap.xml

if [[ $DATABASE = "postgresql" ]] || [[ $DATABASE = "POSTGRESQL" ]]; then
	FNGCDDS=FNGCDDS_pg.xml
    FNDOSDS=OS1DB_pg.xml
	ICNDS=ICNDS_pg.xml
else
	FNGCDDS=FNGCDDS.xml
    FNDOSDS=OS1DB.xml
	ICNDS=ICNDS.xml
fi

# CPE config files
PROPS=props.jar

# DB config files
GCDDB_SCRIPT=GCDDB.sh
OS1DB_SCRIPT=OS1DB.sh
ICNDB_SCRIPT=ICNDB.sh
ENV_LIST=.env_list
SETUP_DB=setup_db.sh
DB2_ONE_SCRIPT=DB2_ONE_SCRIPT.sql

# CPE container parameters
DOCKER_REGISTRY_URL=ibmcom
CPE_CONTAINER_NAME=cpe
CPE_HTTP_PORT=9080
CPE_HTTPS_PORT=9443
#CPE_IMAGE_NAME=filenet_content_platform_engine
#CPE_IMAGE_TAG=latest
CPE_CONTAINER_HOST_NAME=cpe-host1
CPE_RESTART=unless-stopped

# ICN container parameters
ICN_CONTAINER_NAME=icn
ICN_HTTP_PORT=9081
ICN_HTTPS_PORT=9444
#ICN_IMAGE_NAME=content_navigator
#ICN_IMAGE_TAG=latest
ICN_RESTART=unless-stopped

# DB2 container parameters
DB2_CONTAINER_NAME=db2
DB2_HOST_NAME=db2server_V11.5.5.1
DB2_HTTP_PORT=50000
DB2_RESTART=unless-stopped
DB2_PRIVILEGED=true

# Postgres container parameters
PG_CONTAINER_NAME=postgresql
PG_HTTP_PORT=5432
PG_RESTART=unless-stopped

# LDAP container parameters
LDAP_CONTAINER_NAME=ldap
LDAP_PORT=389
LDAP_HTTP_PORT=80
LDAP_RESTART=unless-stopped

# JDK container parameters
JDK_IMAGE_NAME=ibmjava
JDK_IMAGE_TAG=8-sdk
JDK_CONTAINER_NAME=ibmjdk

# CPE domain parameters
P8ADMIN_USER=P8Admin
P8ADMIN_GROUP=P8Admins

# Workflow system parameters
ISOLATED_REGION=IR01
PE_CONNPT_NAME=P8ConnPt1
PE_REGION_NUMBER=1
SYSTEM_ADMIN_GROUP=P8Admins
SYSTEM_CONFIG_GROUP=P8Admins

# LDAP parameters
LDAP_BASE_DN="dc=ecm,dc=ibm,dc=com"
LDAP_DOMAIN="ecm.ibm.com"
LDAP_LDIF="
dn: cn=P8Admin,dc=ecm,dc=ibm,dc=com
cn: P8Admin
sn: P8Admin
userpassword: $GLOBAL_PASSWORD
objectclass: top
objectclass: organizationalPerson
objectclass: person

dn: cn=tester,dc=ecm,dc=ibm,dc=com
cn: tester
sn: tester
userpassword: $GLOBAL_PASSWORD
objectclass: top
objectclass: organizationalPerson
objectclass: person

dn: cn=P8Admins,dc=ecm,dc=ibm,dc=com
objectclass: groupOfNames
objectclass: top
cn: P8Admins
member: cn=P8Admin,dc=ecm,dc=ibm,dc=com

dn: cn=GeneralUsers,dc=ecm,dc=ibm,dc=com
objectclass: groupOfNames
objectclass: top
cn: GeneralUsers
member: cn=P8Admin,dc=ecm,dc=ibm,dc=com
member: cn=tester,dc=ecm,dc=ibm,dc=com
"
#read acl for everybody
LDAP_ACL="
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: to * by * read
"

########################
# For future releases  #
########################

# Bluemix credentials
GET_IMAGE_FROM_BLUEMIX=NO
APIKEY=
BLUEMIX_URL=registry.ng.bluemix.net/ecmcondev
