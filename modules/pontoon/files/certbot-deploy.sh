#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

set -e
set -u
set -x

pushd $RENEWED_LINEAGE

# haproxy < 2.2 supports only combined cert+key
cat fullchain.pem privkey.pem > combined.pem
chmod 0600 combined.pem

systemctl try-reload-or-restart haproxy
