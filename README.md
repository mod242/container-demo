# ECM-Container-PIT Overview
The all-in-one installation tool for containers installs all the required software and configuration information needed to deploy FileNet P8 Platform in a container environment. This tool quickly creates functional P8 Platform environments for demo or non-production purposes only.

In a standard container deployment, you use your existing database and directory server installations, or create new ones, to support the content management services containers. With the container platform installation tool, however, those supporting software prerequisites are installed and configured by the tool. The result is a complete container platform that is ready to use in a very short amount of time.

Because this complete platform relies on open LDAP and a generic database configuration, this installation method is not appropriate for production-level use. You can use this platform installation tool to create environments for demonstration or testing purposes, or to try out the P8 Platform system in a container environment before you move to containers.

The platform installation tool requires library files and service containers from a number of different locations. Before you begin, verify that you have valid login credentials for the following image sources:

    The Docker hub
    The Docker store
    The IBM Github repository
    IBM Passport Advantage
	
This utility contains scripts to set up an IBM Content Fundation docker environment by performing the following tasks:

- Configure and start all the required containers.
- Create the users and groups in OpenLDAP
- Create and configure databases in DB2
- Create a FileNet P8 Domain, object store and workflow system.
- Create an IBM Content Navigator repository and desktop.

# Preconditions
## System requirements
- Supported platform: 
  - Ubuntu 16.04 and above 
  - Mac OS 10.10.1 and above
- Minimum configuration: 2 CPU cores, 8 GB RAM, 50GB free space
- Network with internet access
- Docker CE or EE 17.x.x and above
- OpenLDAP 1.2.1 container from [Docker Hub](https://github.com/osixia/docker-openldap)
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
If you are using MacOS, manual interation is required at two points during installation. First need manual dismiss a dialog during the first luanch of Docker, second need manual adjust the allocated memory to Docker.

Docker will be installed automatically if not already installed, there will be a welcome dialog during first luanch and after that it requires an operating system password to get privileged access. You have to manually input the password to complete the Docker installation.

After the installation of Docker, you need to manually adjust the allocated memory for Docker, by default it is 2 GB, we require it to be at least 4GB. To adjust, click the Docker icon on the menu bar, then click Preferences -> Advanced; increase the number to 4GB memory, then click Apply & Restart. For more information, check [this documentation](https://docs.docker.com/docker-for-mac/#preferences).

## 3. No data persistence
Stopping and starting the containers does not destroy any data. However, if you delete the containers, you will lose all data in the environment. 


# Quick start
1. On your target server, install the Docker libraries for a container platform. Procedures vary by server platform. See the following links for detailed instructions:
        Install Docker CE For Ubuntu
        Installa Docker for Mac

Download the OpenLDAP container from the [Docker hub](https://hub.docker.com/r/osixia/openldap/)

Download the DB2 V11.1.3.3 Developer-C Edition container from the [Docker Store](https://store.docker.com/images/db2-developer-c-edition)

Create a directory on your target server for the ECM container downloads.

Download the following containers from IBM Passport Advantage and save them to your download directory.
        IBM Content Platform Engine container
        IBM Content Navigator container

Download the container platform installation tool from the Github repository and save it to your download directory. 
    
Extract the contents of the container platform installation tool archive file.

Review both the license agreement files.

Open the setProperties.sh file for editing, and update the following information:
- Set the DOWNLOAD_LOCATION paramter value to the location (full path) of the directory you created in step 2
	```DOWNLOAD_LOCATION=<path to downloaded container image (.tar) files>```
- Set the LICENSE_ACCEPTED parameter value
	```LICENSE_ACCEPTED=true``` (after reviewing license file ```LICENSE.txt```)
 - Update all other required parameter values.
- Save your changes.
    
From the command line, in the same directory as the tool, run the container platform installation tool command:
```sudo ./cpit.sh```

After the tool completes, review the output log file, cpit_log.log.

Run the command ```$docker ps``` to make sure the following docker containers are up and running:
- ldap
- db2
- cpe
- icn

Verify the container deployment by logging in to the following applications:
        Administration Console for Content Platform Engine: http://<hostname>:9080/acce
        IBM Content Navigator: http://<hostname>:9080/navigator

# Usage
## Mount volume locations
The mount volumes specified in the setProperties.sh file will be created under the home folder of the user that is currently logged in.
E.g., if you login as root and the mount volume for CPE is set to ```CPE_CONFIGFILES_LOC=/home/cpe_data```, then during execution it will be modified to ```CPE_CONFIGFILES_LOC=/root/home/cpe_data``` and the folder /root/home/cpe_data will be created to store all the configuration files.

## Userful info
- For details of IBM Content Platform Engine, check [here] (https://github.com/ibm-ecm/container-cpe)
- For details of IBM Content Navigator, check [here] (https://github.com/ibm-ecm/container-icn)

# Support
Support can be obtained at [IBM® DeveloperWorks Answers](https://developer.ibm.com/answers/)
<br>
Use the ECM-CONTAINERS tag and assistance will be provided.<br>
*Note: Limited support available during Early Adopter Program*
 