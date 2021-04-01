#!/bin/bash

set -e
set -u
set -x

pushd $RENEWED_LINEAGE

# haproxy < 2.2 supports only combined cert+key
cat fullchain.pem privkey.pem > combined.pem
chmod 0600 combined.pem
