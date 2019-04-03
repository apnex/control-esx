#!/bin/bash

#VMware-VMvisor-Installer-6.7.0.update01-10302608.x86_64.iso
ESXISO="${1}"

# COLOURS
GREEN='\033[0;32m' # green
ORANGE='\033[0;33m' # orange
CYAN='\033[0;36m' # cyan
NC='\033[0m' # no colour
function corange {
	local STRING=${1}
	printf "${ORANGE}${STRING}${NC}"
}
function cgreen {
	local STRING=${1}
	printf "${GREEN}${STRING}${NC}"
}
function ccyan {
	local STRING=${1}
	printf "${CYAN}${STRING}${NC}"
}

function setParams {
	## capture multi-digit build number on VMvisor iso
	REGEX="VMware-VMvisor-Installer-([0-9]{1}\.[0-9]{1}\.[0-9]{1}).*-([0-9]{4,})\.x86_64\.iso$"
	if [[ "${ESXISO}" =~ $REGEX ]]; then
		VERSION="${BASH_REMATCH[1]}"
		BUILD="${BASH_REMATCH[2]}"
	fi

	## set esx directory name
	ESXNAME="esxi-$VERSION-$BUILD"
	BASEDIR="${PWD}/html"
	ESXDIR="$BASEDIR/$ESXNAME"
	echo "ISO: "$ESXISO
}

function buildRepo {
	# check for old esx directories and remove
	REGEX="^.*/(esxi.*)$"
	for DIR in ${BASEDIR}/*; do
		if [[ -d "$DIR" && ! -L "$DIR" ]]; then
			if [[ $DIR =~ $REGEX ]]; then
				OLDESX="${BASH_REMATCH[1]}"
				echo "UMOUNT & DELETE: "$DIR
				umount $DIR
				rm -rf $DIR
			fi
		fi
	done

	# create and mount new esx directory
	echo "CREATE & MOUNT: "$ESXDIR
	mkdir -p $ESXDIR
	mount -o loop,ro $ESXISO $ESXDIR

	# set up boot files
	cp $ESXDIR/efi/boot/bootx64.efi $BASEDIR/mboot.efi
	cp $ESXDIR/mboot.c32 $BASEDIR/mboot.c32
	cat $ESXDIR/boot.cfg | sed -e "s#/##g" -e "s#^prefix=.*#prefix=http://boot.lab:5081/$ESXNAME#" -e "s#runweasel#runweasel ks=http://boot.lab:5081/ks.cfg#" > $BASEDIR/boot.cfg # 6.7
}

if [[ -f "${ESXISO}" ]]; then
	setParams
	buildRepo

	# remove and rebuild image
	docker rmi -f apnex/control-esx 2>/dev/null
	docker build --no-cache -t apnex/control-esx -f control-esx.docker .
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "build") $(ccyan "<esx.iso.path>")\n" 1>&2
fi
