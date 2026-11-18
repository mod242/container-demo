#!/bin/bash
#
# Copies the Content Platform Engine client libraries (Jace.jar, pe.jar, pe3pt.jar, peResources.jar)
# from the CPE container image into install-scripts/CPELibs, so that the Java tools used to create
# the P8 domain, object store and workflow system always match the CPE server version.
#
# The image file system is read with "docker export", so no tools are required inside the image.
# If the libraries cannot be found, the existing files in CPELibs are kept and a warning is printed.
#
echo "=========================================="
echo "Begin extractCPELibs.sh"
date
if [[ $ScriptsDir = "" ]]; then
	source ./d_utils.sh
	echo $ScriptsDir
fi
source $ScriptsDir/../setProperties.sh

CPELibs=$ScriptsDir/CPELibs
CPE_IMAGE=$CPE_REGISTRY_URL/$CPE_IMAGE_NAME:$CPE_IMAGE_TAG
CLIENT_JARS="Jace.jar pe.jar pe3pt.jar peResources.jar"
MARKER=$CPELibs/.source-image

function tarWildcardOpt() {
	# GNU tar needs --wildcards for member patterns, bsdtar (macOS) does not know the option
	if tar --version 2>/dev/null | grep -q "GNU tar"; then
		echo "--wildcards"
	fi
}

function findClientJars() {
	# $1: directory with extracted files; prints the directory that holds Jace.jar (preferably together with pe.jar)
	local dir
	for jace in $(find "$1" -type f -name Jace.jar 2>/dev/null); do
		dir=$(dirname "$jace")
		if [[ -f "$dir/pe.jar" ]]; then
			echo "$dir"
			return 0
		fi
	done
	jace=$(find "$1" -type f -name Jace.jar 2>/dev/null | head -n 1)
	if [[ "$jace" != "" ]]; then
		dirname "$jace"
	fi
}

function extractFromArchives() {
	# $1: directory with extracted .ear/.war/.zip files, $2: target directory
	python3 - "$1" "$2" $CLIENT_JARS <<'EOF'
import io, os, sys, zipfile
src, dst, wanted = sys.argv[1], sys.argv[2], set(sys.argv[3:])
found = {}
def scan(zf, depth=0):
    for name in zf.namelist():
        base = os.path.basename(name)
        if base in wanted and base not in found:
            found[base] = zf.read(name)
        elif depth < 3 and name.lower().endswith(('.ear', '.war', '.zip', '.rar')):
            try:
                scan(zipfile.ZipFile(io.BytesIO(zf.read(name))), depth + 1)
            except zipfile.BadZipFile:
                pass
for root, _, files in os.walk(src):
    for f in files:
        if f.lower().endswith(('.ear', '.war', '.zip')):
            try:
                scan(zipfile.ZipFile(os.path.join(root, f)))
            except zipfile.BadZipFile:
                pass
os.makedirs(dst, exist_ok=True)
for base, data in found.items():
    with open(os.path.join(dst, base), 'wb') as out:
        out.write(data)
print("Found in archives: " + (", ".join(sorted(found)) or "nothing"))
EOF
}

function extractCPELibs() {
	if [[ -f $MARKER ]] && [[ "$(cat $MARKER)" == "$CPE_IMAGE" ]]; then
		echo "Client libraries in $CPELibs already match $CPE_IMAGE, skipping extraction"
		return 0
	fi

	docker image inspect $CPE_IMAGE > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo -e "\033[33mCPE image $CPE_IMAGE not found locally, keeping existing client libraries in $CPELibs\033[0m"
		return 0
	fi

	tmpdir=$(mktemp -d)
	cid=$(docker create $CPE_IMAGE)
	echo "Searching CPE client libraries in $CPE_IMAGE ..."
	# Quoted array, so the shell does not expand the patterns against the current directory
	patterns=()
	for jar in $CLIENT_JARS; do
		patterns+=("*/$jar")
	done
	docker export $cid | tar -x $(tarWildcardOpt) -C $tmpdir/ -f - "${patterns[@]}" 2>/dev/null || true
	libdir=$(findClientJars $tmpdir)

	# Since CPE 26.0.0 only Jace.jar is shipped as a plain file (jaceLib), pe.jar and peResources.jar
	# exist only inside Engine-liberty.ear, so search the archives for every jar that is still missing
	missing=""
	for jar in $CLIENT_JARS; do
		if [[ "$libdir" == "" ]] || [[ ! -f $libdir/$jar ]]; then
			missing="$missing $jar"
		fi
	done
	if [[ "$missing" != "" ]]; then
		echo "Not found as plain files:$missing, searching the application archives ..."
		docker export $cid | tar -x $(tarWildcardOpt) -C $tmpdir/ -f - '*.ear' '*.war' '*.zip' 2>/dev/null || true
		extractFromArchives $tmpdir $tmpdir/fromArchives
		if [[ "$libdir" == "" ]]; then
			libdir=$(findClientJars $tmpdir/fromArchives)
		fi
	fi
	docker rm $cid > /dev/null

	if [[ "$libdir" == "" ]]; then
		echo -e "\033[33mCould not find Jace.jar in $CPE_IMAGE, keeping existing client libraries in $CPELibs\033[0m"
		rm -fr $tmpdir
		return 0
	fi

	echo "Using client libraries from ${libdir#$tmpdir}"
	mkdir -p $CPELibs
	for jar in $CLIENT_JARS; do
		src=$libdir/$jar
		if [[ ! -f $src ]]; then
			src=$(find $tmpdir -type f -name $jar | head -n 1)
		fi
		if [[ -f $src ]]; then
			cp -f $src $CPELibs/$jar
			echo -e "  - updated $jar (from ${src#$tmpdir})"
		else
			echo -e "\033[33m  - $jar not found in image, keeping existing file\033[0m"
		fi
	done
	echo "$CPE_IMAGE" > $MARKER
	rm -fr $tmpdir
	echo -e "\033[36mFinished copying the CPE client libraries to $CPELibs \033[0m"
}

extractCPELibs
echo "=========================================="
