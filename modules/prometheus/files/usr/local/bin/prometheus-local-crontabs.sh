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

set -o errexit
set -o nounset
set -o pipefail

OUTFILE="${1:-/var/lib/prometheus/node.d/local_crontab.prom}"

# Users allowed to have local crontabs
ALLOWED=('root' 'puppet' 'prometheus')

# Get an array of all crontab files
mapfile -t CRONTABS < <(/usr/bin/sudo -u root /bin/ls -1 /var/spool/cron/crontabs/)
# Find the intersection of the local crontabs and the allowed crontabs
mapfile -t ALLOWED_CRONTABS < <(echo ${CRONTABS[@]} ${ALLOWED[@]} | tr ' ' '\n' | sort | uniq -d)

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
