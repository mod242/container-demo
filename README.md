# ECM Container Platform Installation Tool 

# Overview
The all-in-one installation tool for containers installs all the required software and configuration information needed to deploy FileNet P8 Platform in a container environment. This tool quickly creates functional P8 Platform environments for demo or non-production purposes only.

In a standard container deployment, you use your existing database and directory server installations, or create new ones, to support the content management services containers. With the container platform installation tool, however, those supporting software prerequisites are installed and configured by the tool. The result is a complete container platform that is ready to use in a very short amount of time.

Because this complete platform relies on OpenLDAP and a generic DB2 database configuration, this installation method is not appropriate for production-level use. You can use this platform installation tool to create environments for demonstration or testing purposes, or to try out the P8 Platform system in a container environment before you move to containers.

The platform installation tool requires library files and service containers from a number of different locations. Before you begin, verify that you have valid login credentials for the following image sources:

    The Docker hub
    The Docker store
    The IBM Github repository
    IBM Passport Advantage
	
This utility contains scripts to set up an IBM Content Foundation docker environment by performing the following tasks:

- Configure and start all the required containers.
- Create the LDAP users and groups
- Create and configure DB2 databases
- Create a FileNet P8 Domain, object store and workflow system.
- Create an IBM Content Navigator repository and desktop.

# Supported Platforms
The Container Platform Installation Tool is only supported on these operating systems:
1. Ubuntu Linux 16.04.1 LTS (or higher)
2. MacOS 10.13.5 (or higher)

# Prerequisites
## System hardware requirements
- Minimum configuration: 2 CPU cores, 8 GB RAM, 50GB free space
- Network with internet access

## System software requirements
- Docker CE or EE 17.x.x and above
- OpenLDAP 1.2.1 container from [Docker Hub](https://hub.docker.com/r/osixia/openldap/)
- Db2 Developer C 11.1.3.3x-x86_64 container from [Docker Store](https://store.docker.com/images/db2-developer-c-edition)
- IBM Content Platform Engine and IBM Content Navigator container images from [IBM Passport Advantage](https://www-01.ibm.com/software/passportadvantage/pacustomers.html)
- ECM Container PIT installer from [GitHub](https://github.com/ibm-ecm/container-demo)

# Limitations
## 1. Special notice for systems with multiple accounts
This utility requires administrative privileges to install system packages, so it must be run as the "root" user.

If there are multiple system accounts on the target machine and you are unable to login as root (especially on MacOS), then you should check the account user ids and login with the account that has a user id 501. Otherwise you will have DB2 permission issues. Most often the user account created first will be assigned a user id 501.

The command to check the user id is:
```id $user_name``` 
E.g., ```id root``` will print the root id info like below:

```uid=0(root) gid=0(root) groups=0(root)```

## 2. Special actions required for Mac
If you are using MacOS, manual interaction is required at two points during installation. First you need to manually dismiss a dialog during the first launch of Docker. Second, you need to manually adjust the memory allocated to Docker.

During the Docker installation, there will be a welcome dialog during first launch and after that it requires an operating system password to get privileged access. You have to manually input the password to complete the Docker installation.

After the installation of Docker, you need to manually adjust the allocated memory for Docker, by default it is 2 GB, we require it to be at least 4 GB. To adjust, click the Docker icon on the menu bar, then click Preferences -> Advanced; increase the number to 4 GB memory, then click Apply & Restart. For more information, check [this documentation](https://docs.docker.com/docker-for-mac/#preferences).

## 3. Symbol characters in password
The global password parameter used for all LDAP and database user accounts only supports lowercase, uppercase alphabetic characters and numbers. No symbols are allowed.

## 4. No data persistence
Stopping and starting the containers does not destroy any data. However, if you delete the containers, you will lose all data in the environment. 



# Quick start
1. On your target server, install the Docker libraries for a container platform. Procedures vary by server platform. See the following links for detailed instructions:

	- [Install Docker CE For Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
	- [Installa Docker for Mac](https://docs.docker.com/docker-for-mac/install/)

2. Download the OpenLDAP container from the [Docker hub](https://hub.docker.com/r/osixia/openldap/)

3. Download the DB2 V11.1.3.3 Developer-C Edition container from the [Docker Store](https://store.docker.com/images/db2-developer-c-edition)

4. Create a directory on your target server for the ECM container downloads.

5. Download the following containers from IBM Passport Advantage and save them to your download directory.
	- IBM Content Platform Engine container
	- IBM Content Navigator container

6. Download the container platform installation tool from the [Github repository](https://github.com/ibm-ecm/container-demo) and save it to your download directory. 
    
7. Extract the contents of the container platform installation tool archive file.

8. Review both the license agreement files: ```FNCS_License.txt``` and ```ICN_License.txt```

9. Open the ```setProperties.sh``` file for editing, and update the following information:
	- Set the GLOBAL_PASSWORD 
	- Set the DOWNLOAD_LOCATION parameter value to the location (full path) of the directory you created in step 4:<br>
	```DOWNLOAD_LOCATION=<path to downloaded container image (.tar) files>```
	- Set the LICENSE_ACCEPTED parameter value after reviewing both license files:<br>
	```LICENSE_ACCEPTED=true```
	- Update the DB2 and OpenLDAP container image names and tags. To obtain this information use the command:<br>
	```sudo docker images```
	- Update other required parameter values.
	- Save your changes.
    
10. From the command line, in the same directory as the tool, run the container platform installation tool command:<br>
```sudo ./cpit.sh```

# Post-install verification
1. After the tool completes, review the output log file ```cpit_log.log```

2. Run the command ```$docker ps``` to make sure the following docker containers are up and running:
	- ldap
	- db2
	- cpe
	- icn

3. Verify the container deployment by logging in to the following applications:
	- Administration Console for Content Platform Engine: http://hostname:9080/acce
		- User name: P8Admin
		- Password: GLOBAL_PASSWORD
	
	- IBM Content Navigator: http://hostname:9081/navigator
		- User name: P8Admin
		- Password: GLOBAL_PASSWORD

# Remove the Container Platform Installation Tool
1. To remove the software components installed by the Container PIT, run the command:<br>
```sudo install-scripts/cleanup.sh```

2. Delete the folder containing the extracted Container PIT archive 

# Usage
## Mount volume locations
The mount volumes specified in the setProperties.sh file will be created under the home folder of the user that is currently logged in.
E.g., if you login as root and the mount volume for CPE is set to ```CPE_CONFIGFILES_LOC=/home/cpe_data```, then during execution it will be modified to ```CPE_CONFIGFILES_LOC=/root/cpit_data/cpe_data``` and the folder /root/cpit_data/cpe_data will be created to store all the configuration files.

# Known Issues
## DB2 Tablespace Limitations
The Db2 Developer-C Edition container has the following table space limitations:
- User-defined SMS and DMS table spaces are not supported.
- When creating an auto-resize table space without specifying MAXSIZE, the maximum table space size is implicitly set to the remaining capacity of the defined storage limit.
- Altering a table space that is larger than the defined storage limit is not allowed.

Due to these limiations the following exception is seen when trying to add and configure the IBM Content Search Services 5.5.1 container to the environment:

	com.filenet.api.exception.EngineRuntimeException: FNRCD0009E: DB_ERROR: Database access failed with the following error: 
	Error Code -286, message 'A table space could not be found with a page size of at least "8192" that authorization ID
	"DB2INST1" is authorized to use.. SQLCODE=-286, SQLSTATE=42727, DRIVER=4.13.80' ObjectStore: "P8ObjectStore", 
	SQL: ""DECLARE GLOBAL TEMPORARY TABLE SESSION.TMPe8a21922cf5e583 (queried_object_id varchar(16) for bit data , 
	rank double , summary vargraphic(1024) , index_id varchar(16) for bit data , continue_from vargraphic(36) ,
	highlight_blob varchar(2050) for bit data , seqnum integer ) ON COMMIT PRESERVE ROWS "" 

## DB2 Container initialization exception
The Db2 Developer-C Edition container - db2_developer_c:11.1.3.3b-x86_64 - shows the following exception in the container logs:<br> 
	`(*) Cataloging existing databases`<br>
	**`ls: cannot access /database/data/db2inst1/NODE0000: No such file or directory`**<br>
	`(*) Applying Db2 license ...`
<br>This exception can be ignored as it does not affect the funtionality of the DB2, CPE or Content Navigator containers. 

# ECM product info
- [IBM Content Platform Engine Knowledge Center](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.5.0/com.ibm.p8toc.doc/welcome_p8.htm)
- [IBM Content Navigator Knowledge Center](https://www.ibm.com/support/knowledgecenter/SSEUEX_3.0.4/KC_ditamaps/contentnavigator.htm)



# Support
Support can be obtained at [IBM® DeveloperWorks Answers](https://developer.ibm.com/answers/)
<br>
Use the ECM-CONTAINERS tag and assistance will be provided.<br>

 
