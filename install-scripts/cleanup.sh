#!/bin/bash
#
# Licensed Materials - Property of IBM
# 5747-SM3
# (c) Copyright IBM Corp. 2017, 2021  All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Removes the Container PIT environment and nothing else:
#   - the containers created by cpit.sh (matched by their exact names from setProperties.sh)
#     together with their anonymous volumes
#   - the mounted data folders (.../cpit_data/<name>_data), the extraction folder and the install status
#   - optionally (--images) the container images used by Container PIT, if no other container uses them
# Other containers, images, volumes and installed system packages are not touched.
#
# Usage: sudo install-scripts/cleanup.sh [--dry-run] [-y|--yes] [--images]

ScriptsDir=$(cd "$(dirname "$0")"; pwd)
source "$ScriptsDir/../setProperties.sh"

DRY_RUN=false
ASSUME_YES=false
REMOVE_IMAGES=false

function usage() {
	echo "Usage: $0 [--dry-run] [-y|--yes] [--images]"
	echo "  --dry-run   only show what would be removed"
	echo "  -y, --yes   do not ask for confirmation"
	echo "  --images    also remove the container images used by Container PIT"
}

for arg in "$@"; do
	case $arg in
		--dry-run) DRY_RUN=true ;;
		-y|--yes) ASSUME_YES=true ;;
		--images) REMOVE_IMAGES=true ;;
		-h|--help) usage; exit 0 ;;
		*) echo "Unknown option: $arg"; usage; exit 1 ;;
	esac
done

# On Linux the data folders are created by root (sudo cpit.sh) and contain files of the container users
if [[ "$(uname -s)" == "Linux" ]] && [[ $(id -u) -ne 0 ]]; then
	if $DRY_RUN; then
		echo -e "\033[33mNot running as root: data folders of other users (e.g. /root/cpit_data) are not visible\033[0m"
	else
		echo -e "\033[31mPlease run the cleanup as root: sudo $0 $*\033[0m"
		exit 1
	fi
fi

if ! docker info > /dev/null 2>&1; then
	echo -e "\033[31mCannot connect to Docker. Is Docker running and are you allowed to use it (sudo)?\033[0m"
	exit 1
fi

CONTAINERS="$JDK_CONTAINER_NAME $ICN_CONTAINER_NAME $CPE_CONTAINER_NAME $LDAP_CONTAINER_NAME $PG_CONTAINER_NAME $DB2_CONTAINER_NAME"
IMAGES="$CPE_REGISTRY_URL/$CPE_IMAGE_NAME:$CPE_IMAGE_TAG
$ICN_REGISTRY_URL/$ICN_IMAGE_NAME:$ICN_IMAGE_TAG
$JDK_IMAGE_NAME:$JDK_IMAGE_TAG
$LDAP_REGISTRY_URL/$LDAP_IMAGE_NAME:$LDAP_IMAGE_TAG
$PG_REGISTRY_URL/$PG_IMAGE_NAME:$PG_IMAGE_TAG
$DB2_REGISTRY_URL/$DB2_IMAGE_NAME:$DB2_IMAGE_TAG"

function run() {
	if $DRY_RUN; then
		echo "  [dry-run] $*"
	else
		"$@" > /dev/null
	fi
}

function isContainerPITContainer() {
	for name in $CONTAINERS; do
		if [[ "$1" == "$name" ]]; then
			return 0
		fi
	done
	return 1
}

function existingContainers() {
	# Exact name match, "docker ps --filter name=" alone would also match substrings
	for name in $CONTAINERS; do
		if [[ "$(docker ps -a -q --filter "name=^/${name}\$")" != "" ]]; then
			echo "$name"
		fi
	done
}

function dataDirs() {
	# Data folders are always <home>/cpit_data/<name>_data (see updateConfigFiles.sh). Collect them from the
	# mounts of the existing containers, from setProperties.sh and from the home folder of the current user,
	# and only accept paths with that layout, so no other folder can be removed by accident.
	{
		for name in $(existingContainers); do
			docker inspect -f '{{range .Mounts}}{{if eq .Type "bind"}}{{println .Source}}{{end}}{{end}}' "$name"
		done
		echo "$CPE_CONFIGFILES_LOC"
		echo "$ICN_CONFIGFILES_LOC"
		echo "$PG_CONFIGFILES_LOC"
		echo "$DB2_CONFIGFILES_LOC"
		home=$(cd ~; pwd)
		for name in cpe icn pg db2; do
			echo "$home/cpit_data/${name}_data"
		done
	} | sed -n -E 's#^(/.+/cpit_data/[^/]+_data)(/.*)?$#\1#p' | sort -u | while read -r dir; do
		if [[ -d "$dir" ]]; then
			echo "$dir"
		fi
	done
}

function existingImages() {
	echo "$IMAGES" | while read -r image; do
		if docker image inspect "$image" > /dev/null 2>&1; then
			echo "$image"
		fi
	done
}

containers=$(existingContainers)
dirs=$(dataDirs)
statusFiles=$(ls "$ScriptsDir"/status.log "$ScriptsDir"/status.log.bak 2>/dev/null)
tempDir=""
if [[ "$TEMP_LOCATION" != "" ]] && [[ "$TEMP_LOCATION" != "/" ]] && [[ -d "$TEMP_LOCATION" ]]; then
	tempDir=$TEMP_LOCATION
fi
images=""
if $REMOVE_IMAGES; then
	images=$(existingImages)
fi

echo "=========================================="
date
echo "The following Container PIT components will be removed:"
echo "  Containers:   ${containers:-none}" | tr '\n' ' '; echo
echo "  Data folders: ${dirs:-none}" | tr '\n' ' '; echo
echo "  Status files: ${statusFiles:-none}" | tr '\n' ' '; echo
echo "  Temp folder:  ${tempDir:-none}"
if $REMOVE_IMAGES; then
	echo "  Images:       ${images:-none}" | tr '\n' ' '; echo
else
	echo "  Images:       kept (use --images to remove them)"
fi

if [[ "$containers$dirs$statusFiles$tempDir$images" == "" ]]; then
	echo "Nothing to remove."
	exit 0
fi

if ! $DRY_RUN && ! $ASSUME_YES; then
	while true; do
		echo -e "\033[32mAre you sure you want to remove the Container PIT components?(y/n)\033[0m"
		read -r choice
		case $choice in
			y|Y) break ;;
			n|N) echo -e "\033[31mAborting environment cleanup.....\033[0m"; exit 0 ;;
			*) echo -e "\033[31mUnexpected input\033[0m" ;;
		esac
	done
fi

failed=false

for name in $containers; do
	echo "Removing container $name and its anonymous volumes..."
	run docker rm -f -v "$name" || failed=true
done

for dir in $dirs; do
	echo "Removing data folder $dir..."
	run rm -rf "$dir" || failed=true
	if ! $DRY_RUN && [[ -d "$dir" ]]; then
		failed=true
	fi
	# Remove the parent cpit_data folder once it is empty
	if ! $DRY_RUN; then
		rmdir "$(dirname "$dir")" 2>/dev/null
	fi
done

if [[ "$tempDir" != "" ]]; then
	echo "Removing extraction folder $tempDir..."
	run rm -rf "$tempDir" || failed=true
fi

for file in $statusFiles; do
	echo "Removing status file $file..."
	run rm -f "$file" || failed=true
done

for image in $images; do
	echo "Removing image $image..."
	# Keep images that are still used by containers outside of Container PIT
	users=""
	for user in $(docker ps -a --filter "ancestor=$image" --format '{{.Names}}'); do
		if ! isContainerPITContainer "$user"; then
			users="$users $user"
		fi
	done
	if [[ "$users" != "" ]]; then
		echo -e "\033[33m  - still used by other containers ($users ), keeping it\033[0m"
		continue
	fi
	run docker rmi "$image" || failed=true
done

if $failed; then
	echo -e "\033[31mSome components could not be removed, see the messages above (missing permissions? run it with sudo)\033[0m"
	exit 1
fi
if $DRY_RUN; then
	echo -e "\033[36mDry run finished, nothing was removed \033[0m"
else
	echo -e "\033[36mFinished removing the Container PIT components \033[0m"
fi
echo "=========================================="
