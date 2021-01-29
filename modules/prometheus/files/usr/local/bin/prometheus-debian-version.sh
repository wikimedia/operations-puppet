#!/bin/bash
# Copyright © 2021 Chris Danis, the Wikimedia Foundation, & contributors
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
# Usage: prometheus-debian-version [output path] [optional override for /etc/debian_version]

set -eu
set -o pipefail

OUTFILE="${1:-/var/lib/prometheus/node.d/debian-version.prom}"
DEBIAN_VERSION_FILE="${2:-/etc/debian_version}"

[ -r "$DEBIAN_VERSION_FILE" ] || exit 0

TMPOUTFILE="${OUTFILE}.$$"
function cleanup {
    rm -f "$TMPOUTFILE"
}
trap cleanup EXIT

VERSION="$(tr -d '\n' < "$DEBIAN_VERSION_FILE")"

cat <<EOF >"$TMPOUTFILE"
# HELP node_debian_version A metric with a constant '1' value with labels the Debian distribution version.
# TYPE node_debian_version gauge
node_debian_version{version="${VERSION}"} 1
EOF

mv "$TMPOUTFILE" "$OUTFILE"
