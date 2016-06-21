#!/bin/bash
# Tool for exporting a docker container fs to a local directory
# with support for uid/gid mapping (for user namespaces)
# Output placed in "./rootfs" in $CWD
# Depends on:
#  1) http://bazaar.launchpad.net/~serge-hallyn/+junk/nsexec/view/head:/uidmapshift.c
#     Build with `gcc -o uidmapshift uidmapshift.c`; place in path
#  2) docker engine installation (for `docker export`)

function usage() {
	cat <<-ENDUSAGE

	exportrootfs.sh [-u <id>] [-r <len>] cntr_name
	Phil Estes <estesp@gmail.com>

    Export container's root filesystem with optional
	file ownership mapping. Must be run as root.
	
	  -u <id> : [optional] specify root of container's ID range
	  -r <len>: [optional] specify length of ID range for containers
	 
ENDUSAGE
}

case "${1}" in
	-h|--help|"")
		usage
		exit 0
esac

if [ `id -u` != 0 ]; then
	echo "ERROR: Please run this script as root so file ownership can be set properly"
	exit 1
fi

while getopts ":u:r:" opt; do
    case $opt in
       u)
          _ROOTID=${OPTARG}
          ;;
       r)
          _IDRANGE=${OPTARG}
          ;;
      \?)
	      echo "ERROR: Invalid option: -$OPTARG" >&2
		  usage
	      exit 1
          ;;
       :)
          echo "ERROR: Option -$OPTARG requires an argument." >&2
		  usage
          exit 1
          ;;
    esac
done

case "${_ROOTID}" in
    *[!0-9]*)
		echo "ERROR: Invalid root ID (${_ROOTID}); must be an integer"
		usage
		exit 1
		;;
    *) ;;
esac

case "${_IDRANGE}" in
    *[!0-9]*)
		echo "ERROR: Invalid ID range (${_IDRANGE}); must be an integer"
		usage
		exit 1
		;;
    *) ;;
esac

[[ ! -z "${_ROOTID}" ]] && [[ -z "${_IDRANGE}" ]] && {
    echo "ERROR: Must specify a range length (-r) if specifying a root ID"
	usage
	exit 1
}
[[ ! -z "${_IDRANGE}" ]] && [[ -z "${_ROOTID}" ]] && {
    echo "ERROR: Must specify a root ID (-u) if specifying a range length"
	usage
	exit 1
}

shift $((OPTIND-1))

if [ -z "${1}" ]; then
	echo "ERROR: Please supply a container name to export"
	usage
	exit 1
fi

mkdir -p rootfs
echo Exporting ${1} filesystem into `pwd`/rootfs.
cd rootfs && docker export "${1}" | tar -xp --numeric-owner

[[ ! -z "${_ROOTID}" ]] && {
   uidmapshift -b `pwd` 0 ${_ROOTID} ${_IDRANGE}
}
