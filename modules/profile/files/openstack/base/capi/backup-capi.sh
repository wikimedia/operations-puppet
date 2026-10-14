#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
set -euxo pipefail
DATE=$(date '+%Y%m%d')

systemctl stop k3s
tar -cavzf "$1"/capi-backup-"$DATE".tgz /var/lib/rancher/k3s/server/db/
cp /var/lib/rancher/k3s/server/token "$1"/rancher-k3s-server-token-"$DATE"
systemctl start k3s
