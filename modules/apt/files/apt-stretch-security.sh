#!/bin/bash

set -e

LIST_FILE=$(mktemp)
echo "deb http://security.debian.org/ stretch/updates main contrib non-free" >> $LIST_FILE
echo "deb http://deb.debian.org/debian/ stretch main contrib non-free" >> $LIST_FILE

POLICY_FILE=$(mktemp)
cat << EOF >> $POLICY_FILE
Package: *
Pin: release l=Debian-Security
Pin-Priority: 990

Package: *
Pin: release l=Debian
Pin-Priority: 99
EOF

ARGS="-o Dir::Etc::SourceList=$LIST_FILE -o Dir::Etc::Preferences=$POLICY_FILE -o Dir::Etc::SourceParts=/dev/null"
ARGS2="-y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'"
DEBIAN_FRONTEND=noninteractive apt-get update $ARGS
DEBIAN_FRONTEND=noninteractive apt-get upgrade $ARGS $ARGS2 $@

rm -rf $LIST_FILE
rm -rf $POLICY_FILE
