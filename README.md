# ECM Container Platform Installation Tool 

# Overview
The all-in-one installation tool for containers installs all the required software and configuration information needed to deploy FileNet P8 Platform in a container environment. This tool quickly creates functional P8 Platform environments for demo or non-production purposes only.

In a standard container deployment, you use your existing database and directory server installations, or create new ones, to support the content management services containers. With the container platform installation tool, however, those supporting software prerequisites are installed and configured by the tool. The result is a complete container platform that is ready to use in a very short amount of time.

Because this complete platform relies on openLDAP and a generic database configuration, this installation method is not appropriate for production-level use. You can use this platform installation tool to create environments for demonstration or testing purposes, or to try out the P8 Platform system in a container environment before you move to containers.

This utility contains scripts to set up an IBM FileNet Content Manager docker environment by performing the following tasks::

- Download the following containers from the internal IBM repository:<br>
	- OpenLDAP v1.3.0
	- DB2 v11.5.0.0a 
	- CPE v5.5.5 
	- ICN v3.0.8
- Configure and start all the required containers.
- Create the LDAP users and groups
- Create and configure DB2 databases
- Create a FileNet P8 Domain, object store and workflow system.
- Create an IBM Content Navigator repository and desktop.

# Supported Platforms
The Container Platform Installation Tool is only supported on these operating systems:
1. Ubuntu Linux 18.04 and 20.04
2. MacOS 10.13.5 (or higher)

# Prerequisites
## System hardware requirements
- Minimum configuration: 2 CPU cores, 8 GB RAM, 50GB free space
- Network with internet access

# Limitations
## 1. Special notice for systems with multiple accounts
This utility requires administrative privileges to install system packages, so it must be run as the "root" user.

If there are multiple system accounts on the target machine and you are unable to login as root (especially on MacOS), then you should check the account user ids and login with the account that has a user id 501. Otherwise you will have DB2 permission issues. Most often the user account created first will be assigned a user id 501.

The command to check the user id is:
```id $user_name```<br>
E.g.,<br>
```id root``` will print the root id info like below:<br>

```uid=0(root) gid=0(root) groups=0(root)```

## 2. Special actions required for Mac
If you are using MacOS, manual interaction is required at two points during installation. First you need to manually dismiss a dialog during the first launch of Docker. Second, you need to manually adjust the memory allocated to Docker.

Docker will be installed automatically if not already installed, there will be a welcome dialog during first launch and after that it requires an operating system password to get privileged access. You have to manually input the password to complete the Docker installation.

After the installation of Docker, you need to manually adjust the allocated memory for Docker, by default it is 2 GB, we require it to be at least 4 GB. To adjust, click the Docker icon on the menu bar, then click Preferences -> Advanced; increase the number to 4 GB memory, then click Apply & Restart. For more information, check [this documentation](https://docs.docker.com/docker-for-mac/#preferences).

## 3. No symbol characters in password
The global password parameter used for all LDAP and database user accounts only supports lowercase, uppercase alphabetic characters and numbers. No symbols are allowed.

## 4. No data persistence
Stopping and starting the containers does not destroy any data. However, if you delete the containers, you will lose all data in the environment.


# Quick start
1. Create a directory on your target server for the Container PIT archive.:

2. Download the container platform installation tool (Container-PIT.zip) and save it to your download directory.

3. Extract the contents of the container platform installation tool archive file.

4. Open the setProperties.sh file for editing, and update the required parameter values (if desired)<br>
	- Save your changes.

5. From the command line, in the same directory as the tool, run the container platform installation tool commands:<br>
```sudo chmod 755 cpit.sh```<br>
```sudo ./cpit.sh```


# Post-install verification
1. After the tool completes, review the output log file ```cpit_log.log```

2. Run the command ```$docker ps``` and make sure the following docker containers are up and running:
	- ldap
	- db2
	- cpe
	- icn

3. Verify the container deployment by logging in to the following applications:
	- Administration Console for Content Platform Engine: http://hostname:9080/acce
		- User name: P8Admin
		- Password: GLOBAL_PASSWORD

	- IBM Content Navigator: http://hostname:9080/navigator
		- User name: P8Admin
		- Password: GLOBAL_PASSWORD


# Remove the Container Platform Installation Tool components
To remove the software components installed by the Container PIT, run the command:<br />
```sudo install-scripts/cleanup.sh```


# Usage
## Mount volume locations
The mount volumes specified in the setProperties.sh file will be created under the home folder of the user that is currently logged in.<br>
E.g., if you login as root and the mount volume for CPE is set to ```CPE_CONFIGFILES_LOC=/home/cpe_data```, then during execution it will be modified to ```CPE_CONFIGFILES_LOC=/root/cpit_data/cpe_data``` and the folder ```/root/cpit_data/cpe_data``` will be created to store all the configuration files.<br>


# Troubleshooting
## Hostname resolution
The Content Navigator initialization scripts will fail if the hostname cannot be resolved.<br>
To resolve this issue run the following commands:<br>
1. Determine the hostname using the command:<br>
```uname -n```<br>
2. Edit the file ```/etc/hosts``` and add the hostname as follows:<br>
```127.0.0.1 {hostname}```
 
