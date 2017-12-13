#!/bin/bash

set -e

LIST_FILE=$(mktemp)
echo "deb http://deb.debian.org/debian/ stretch-backports main contrib non-free" >> $LIST_FILE

# no pin/pref file, since default for backports is usually good enough

ARGS="-o Dir::Etc::SourceList=$LIST_FILE -o Dir::Etc::SourceParts=/dev/null"
ARGS2="-y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold'"
DEBIAN_FRONTEND=noninteractive apt-get update $ARGS
DEBIAN_FRONTEND=noninteractive apt-get upgrade $ARGS $ARGS2 $@

rm -rf $LIST_FILE
rm -rf $POLICY_FILE
