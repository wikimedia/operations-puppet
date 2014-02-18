#!/bin/bash
set -e
set -o pipefail
umask 022

if [ $# -ne 2 ]; then
	echo "Usage: $0 <filename> <URL>"
	exit 99
fi

FN=$1
URL=$2

BASE_D='/var/netmapper'
TEMP_D=`/bin/mktemp -dp "${BASE_D}"`
TEMP_FN="${TEMP_D}/${FN}"
FN_ABS="${BASE_D}/${FN}"

function cleanup {
	rm -f "$TEMP_FN"
	rmdir "$TEMP_D"
}
trap cleanup EXIT

wget -q --timeout 47 -O "$TEMP_FN" "$URL"

/usr/bin/vnm_validate "$TEMP_FN"
/usr/bin/cmp -s "$TEMP_FN" "$FN_ABS" || mv -f "$TEMP_FN" "$FN_ABS"
