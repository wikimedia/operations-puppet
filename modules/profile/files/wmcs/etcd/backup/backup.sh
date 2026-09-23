#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
set -euxo pipefail
DATE=$(date '+%Y%m%d')

etcdctl snapshot save /srv/backup/etcd/backup-"$DATE".db
find /srv/backup/etcd -type f -name '*.db' | sort -r | tail -n +6 | xargs -r rm -v
