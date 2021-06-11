#!/usr/bin/env bash
# Copyright 2020 Wikimedia Foundation and contributors
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Usage: prometheus-local_crontabs [outfile]
# This is exclusively tailored for toolforge grid nodes.

set -o errexit
set -o nounset
set -o pipefail

OUTFILE="${1:-/var/lib/prometheus/node.d/local_crontab.prom}"

# Users allowed to have local crontabs
ALLOWED=('root' 'puppet' 'prometheus')

# T284130: Due to a bug on ldap sssd for sudo, if the system has to trigger the oom while trying to run sudo, it will
# end up in a segmentation fault, so we force some memory allocatio before sudo to avoid that from happening.
# TODO: remove once we don't have grid engine in cloud anymore and/or when we upgrade to bullseye
# 4MB, this needs a second shell otherwise the memory does not get freed
/usr/bin/env bash -c 'dummyvar="$(yes | head -c $((4 * 1024 * 1024)))"'

# Get an array of all crontab files
mapfile -t CRONTABS < <(/usr/bin/sudo -u root /bin/ls -1 /var/spool/cron/crontabs/)
# Find the intersection of the local crontabs and the allowed crontabs
mapfile -t ALLOWED_CRONTABS < <(echo "${CRONTABS[@]}" "${ALLOWED[@]}" | tr ' ' '\n' | sort | uniq -d)

# Count members of each array
TOTAL_CRONTABS=${#CRONTABS[@]}
ADMIN_CRONTABS=${#ALLOWED_CRONTABS[@]}

# Compute difference of arrays
OTHER_CRONTABS=$((TOTAL_CRONTABS - ADMIN_CRONTABS))

cat <<EOF > "${OUTFILE}.$$"
# HELP local_crontabs Number of local crontab files on this system
# TYPE local_crontabs gauge
local_crontabs{type="administrative"} ${ADMIN_CRONTABS}
local_crontabs{type="other"} ${OTHER_CRONTABS}
EOF
mv "${OUTFILE}.$$" "${OUTFILE}"
