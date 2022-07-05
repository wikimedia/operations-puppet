#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# check_ring_tarball.sh - checks the contents of a ring tarball ($1)
# specifically:
# that every .builder file therein passes swift-ring-builder validate
# that every .ring.gz file in SWIFTDIR exists therein
# SWIFTDIR defaults to /etc/swift

set -e

shopt -s nullglob

SWIFTDIR="${SWIFTDIR:=/etc/swift}"

if [ "$#" -ne 1 ]; then
    echo "usage: check_ring_tarball.sh /path/to/tarball"
    exit 1
fi

td=$(mktemp -d)
trap 'rm -rf $td' EXIT

#Extract tarball, check all .builder files in it are OK
tar -xf "$1" --one-top-level="$td"
for b in "${td}/"*.builder ; do
    swift-ring-builder "$b" validate
done

#Check every ring in SWIFTDIR has a corresponding ring (and builder)
#file in the tarball
for r in "${SWIFTDIR}/"*.ring.gz ; do
    rn=$(basename "$r")
    if ! [ -f "${td}/${rn}" ]; then
        echo "Ring file $rn missing from tarball"
        exit 1
    fi
    if ! [ -f "${td}/${rn%.ring.gz}.builder" ]; then
        echo "Builder file corresponding to $rn missing from tarball"
        exit 1
    fi
done

#Finally, if there are any rings in SWIFTDIR (i.e. this isn't a
#freshly-installed system), check that every ring file in the tarball
#has a corresponding ring in SWIFTDIR
if [ -n "$(find ${SWIFTDIR} -name '*.ring.gz' -print -quit)" ]; then
    for r in "${td}/"*.ring.gz ; do
        rn=$(basename "$r")
        if ! [ -f "${SWIFTDIR}/${rn}" ]; then
            echo "Ring file $rn in tarball but not $SWIFTDIR"
            exit 1
        fi
    done
fi
