# ECM Container Platform Installation Tool 


# What's new (November 2026)
- Updated to IBM Content Cortex 26.0.1 IF001 (Content Platform Engine and Content Navigator images `26.0.1-IF001` from the IBM Entitled Registry)
- The CPE client libraries (`Jace.jar`, `pe.jar`, `pe3pt.jar`, `peResources.jar`) are now copied from the CPE image into `install-scripts/CPELibs` (`install-scripts/extractCPELibs.sh`), so the domain, object store and workflow setup always uses client libraries that match the server version
- JDK helper container switched from `ibmjava:8-sdk` to IBM Semeru Runtime 21 (`ibm-semeru-runtimes:open-21-jdk`)
- PostgreSQL switched from the frozen `bitnamilegacy/postgresql` image to the official `postgres:17` image
- CPE license model is configurable in `setProperties.sh` (`CPE_LICENSE_MODEL`)
- Since CPE 26.0.0 only `Jace.jar` is shipped as a plain file in the image; `pe.jar`, `pe3pt.jar` and `peResources.jar` are taken from `Engine-liberty.ear`
- HTTPS for CPE and Navigator: the images ship a `key.jks` that does not match their keystore password, so `config-files/common/keystore.xml` lets Liberty generate its own self-signed keystore (`key.p12`)
- Containers reach the Docker host via `--add-host=<hostname>:host-gateway` instead of the hard-coded `172.17.0.1`, so a custom Docker bridge address (`bip`) works as well
- Fixes: host name placeholders in the configuration files, PostgreSQL mount location rewrite in `updateConfigFiles.sh`, PostgreSQL status tracking in `cpit.sh`, docker-py check on Python 3.14, which removed `pkgutil.find_loader` (`gatherHostInfo.sh`), failed ICN desktop creation is no longer reported as successful
- License files updated to the IBM Content Cortex 26.0.1 and Content Navigator license information shipped in the container images (`FNCS_License.txt`, `ICN_License.txt`)
- `cpit.sh` no longer needs root on Linux: run it as a member of the `docker` group, the data is then stored in your own home folder
- `cleanup.sh` only removes the Container PIT containers and data instead of all containers on the host, also removes the PostgreSQL data, no longer uninstalls system packages and supports `--dry-run`, `--images` and `-y`

# Overview
The all-in-one installation tool for containers installs all the required software and configuration information needed to deploy IBM Content Cortex (formerly FileNet Content Manager / FileNet P8 Platform) in a container environment. This tool quickly creates functional P8 Platform environments for demo or non-production purposes only.

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
- PostgreSQL 17 from [Docker Hub](https://hub.docker.com/_/postgres)
- IBM Semeru Runtime 21 JDK from [Docker Hub](https://hub.docker.com/_/ibm-semeru-runtimes)
- Content Platform Engine and Content Navigator 26.0.1 images from the IBM Entitled Registry (`cp.icr.io`), entitlement key required
- ECM Container PIT installer from [GitHub](https://github.com/mod242/container-demo)

**NOTE**: Container PIT scripts cannot be used to upgrade from earlier versions of the Content Platform Engine and Content Navigator containers. **A clean environment is required to run the Container PIT scripts.**

# Limitations
## 1. Special notice for systems with multiple accounts
On Linux, run the installer as a regular user who is a member of the `docker` group (check with ```id -nG```, add with ```sudo usermod -aG docker $USER``` and log in again). Running it with sudo works as well, but then all data is stored under `/root/cpit_data` (see [Mount volume locations](#mount-volume-locations)). Only `cleanup.sh` needs root, because the PostgreSQL data files are owned by the `postgres` user of the container.

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

3. Review the license information files: ```FNCS_License.txt``` (IBM Content Cortex) and ```ICN_License.txt``` (IBM Content Navigator). They are copied from the `/licenses` folder of the Content Cortex container images.

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
		```chmod u+x ./cpit.sh```<br>
        - Run the container platform installation tool (as a member of the `docker` group, without sudo):<br>
        ```./cpit.sh```

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
1. To remove the containers and data created by the Container PIT, run the command:<br>
	```sudo install-scripts/cleanup.sh```<br>
	Only the containers named in `setProperties.sh` (with their anonymous volumes), their data folders (`<home>/cpit_data/<name>_data`), the extraction folder and the install status are removed. Other containers, images and installed packages are not touched.<br>
	Options: `--dry-run` shows what would be removed, `--images` also removes the container images used by the Container PIT (unless another container still uses them), `-y` skips the confirmation.

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
E.g., if you run ```./cpit.sh``` as user `user`, the data is stored under ```/home/user/cpit_data```. If you run it with sudo or as root, ```CPE_CONFIGFILES_LOC``` is modified to ```/root/cpit_data/cpe_data``` and all data is stored under ```/root/cpit_data```.


# ECM product info
- [IBM Content Cortex 26.0.1 documentation](https://www.ibm.com/docs/en/content-cortex/26.0.1)
- [IBM Content Cortex container releases and image tags](https://github.com/ibm-ecm/ibm-content-cortex-containers/releases)

