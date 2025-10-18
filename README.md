# ECM Container Platform Installation Tool 


# Overview
The all-in-one installation tool for containers installs all the required software and configuration information needed to deploy FileNet P8 Platform in a container environment. This tool quickly creates functional P8 Platform environments for demo or non-production purposes only.

In a standard container deployment, you use existing database and directory server installations, or create new ones, to support the content management services containers. With the container platform installation tool, however, those supporting software prerequisites are installed and configured by the tool. The result is a complete container platform that is ready to use in a very short amount of time.

Because this complete platform relies on OpenLDAP and a generic Postgresql database configuration, this installation method is not appropriate for production-level use. You can use this platform installation tool to create environments for demonstration or testing purposes, or to try out the P8 Platform system in a container environment before you move to containers.

The platform installation tool requires library files and service containers from a number of different locations. Before you begin, verify that you have valid login credentials for the following image sources:

    The Docker Hub
    IBM Container Registry

This utility contains scripts to set up an IBM FileNet Content Manager container environment by performing the following tasks:

- Configure and start all the required containers.
- Create the LDAP users and groups
- Create and configure Db2 databases
- Create a FileNet P8 Domain, object store and workflow system.
- Create an IBM Content Navigator repository and desktop.

# Supported Platforms
The Container Platform Installation Tool is only supported on operating systems supporting docker natively.


# Prerequisites
## System hardware requirements
- Minimum configuration: 2 CPU cores, 8 GB RAM, 50GB free space
- Network with internet access

## System software requirements
- Docker CE or EE 20.10.7
- OpenLDAP 1.5.0 container from [Docker Hub](https://hub.docker.com/r/osixia/openldap/)
- PostgreSQL 17 from [Docker Hub](https://hub.docker.com/r/bitnamilegacy/postgresql)
- ECM Container PIT installer from [GitHub](https://github.com/mod242/container-demo)

**NOTE**: Container PIT scripts cannot be used to upgrade from earlier versions of the Content Platform Engine and Content Navigator containers. **A clean environment is required to run the Container PIT scripts.**

# Limitations
## 1. Special notice for systems with multiple accounts
This utility requires administrative privileges to install system packages, so it should be run as the `root` user (or sudo).

If there are multiple system accounts on the target machine and you are unable to login as root (especially on MacOS), then you should check the account user ids and login with the account that has a user id 501. Otherwise you will have Db2 permission issues. Most often the user account created first will be assigned a user id 501.

The command to check the user id is: ```id $user_name```

E.g., ```id root``` will print the root id info like below:

```uid=0(root) gid=0(root) groups=0(root)```

## 2. Special actions required for Mac
If you are using MacOS, manual interaction is required at two points when installing Docker. First you need to manually dismiss a dialog during the first launch of Docker. Second, you need to manually adjust the memory allocated to Docker.

During the Docker installation, there will be a welcome dialog during first launch and after that it requires an operating system password to get privileged access. You have to manually input the password to complete the Docker installation.

After the installation of Docker, you need to manually adjust the allocated memory for Docker, by default it is 2 GB, we require it to be at least 4 GB. To adjust, click the Docker icon on the menu bar, then click Preferences -> Advanced; increase the number to 4 GB memory, then click Apply & Restart. For more information, check [this documentation](https://docs.docker.com/docker-for-mac/#preferences).

## 3. Symbol characters in password
The global password parameter used for all LDAP and database user accounts only supports lowercase, uppercase alphabetic characters and numbers. No symbols are allowed.

## 4. No data persistence
Stopping and starting the containers does not destroy any data. However, if you delete the containers, you will lose all data in the environment.



# Quick start
1. On your target server, install the Docker Engine. 

2. Install Python3

3. Review the license agreement file: ```FNCS_License.txt```

4. Open the ```setProperties.sh``` file for editing, and update the following information:
	- Set the `GLOBAL_PASSWORD`
	- Set the Registry parameter `CP_PASSWORD`
	- Set `CPE_CONFIGFILES_LOC`, `ICN_CONFIGFILES_LOC`, and `PG_CONFIGFILES_LOC`to valid basic storage Locations
	- Set `U_UID`if needed to your id
	- Set the LICENSE_ACCEPTED parameter value after reviewing the license file:<br>
	```LICENSE_ACCEPTED=true```
	- Update other required parameter values if needed.
	- Save your changes.

5. In the Base directory , run these commands:<br>
        - Add execute permissions to the script file:<br>
		```sudo chmod u+x ./cpit.sh```<br>
        - Run the container platform installation tool:<br>
        ```sudo ./cpit.sh```

# Post-install verification
1. After the tool completes, review the output log file ```cpit_log.log```

2. Run the command ```docker ps``` to make sure the following docker containers are up and running:
	- ldap
	- postgresql
	- cpe
	- icn

3. Verify the container deployment by logging in to the following applications:

**NOTE**: Starting with the FileNet P8 v5.5.6 release, only SSL connections to the applications are supported.

	- Administration Console for Content Platform Engine: https://<hostname>:9443/acce
		- User name: P8Admin
		- Password: GLOBAL_PASSWORD

	- IBM Content Navigator: https://<hostname>:9444/navigator
		- User name: P8Admin
		- Password: GLOBAL_PASSWORD

# Remove the Container Platform Installation Tool
1. To remove the software components installed by the Container PIT, run the command:<br>
	```sudo install-scripts/cleanup.sh```

2. Delete the folder containing the extracted Container PIT archive

# Troubleshooting
## Hostname resolution
The Content Navigator initialization scripts will fail if the hostname cannot be resolved.<br>
To resolve this issue do the following:<br>
1. Determine the hostname using the command:<br>
	```uname -n```<br>
2. Edit the file ```/etc/hosts``` and add the hostname as follows:<br>
	```127.0.0.1 hostname```

# Storage
## Mount volume locations
The mount volumes specified in the ```setProperties.sh``` file will be created under the home folder of the user that is currently logged in.<br>
E.g., if you login as root and the mount volume for CPE is set to ```CPE_CONFIGFILES_LOC=~/cpit_data/cpe_data```, then during execution it will be modified to ```CPE_CONFIGFILES_LOC=/root/cpit_data/cpe_data``` and the folder ```/root/cpit_data/cpe_data``` will be created to store all the configuration files.


# ECM product info
- [IBM Content Platform Engine Knowledge Center](https://www.ibm.com/docs/en/filenet-p8-platform/5.7.0)
- [IBM Content Navigator Knowledge Center](https://www.ibm.com/docs/en/content-navigator/3.2.0)

