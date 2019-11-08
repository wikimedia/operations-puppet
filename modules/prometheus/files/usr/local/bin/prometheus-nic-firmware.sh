#!/bin/bash
# Copyright 2019 Chris Danis
#                Wikimedia Foundation
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
# Usage: prometheus-nic-firmware [outfile]

set -eu
set -o pipefail

outfile="$(realpath "${1:-/var/lib/prometheus/node.d/nic_firmware.prom}")"
tmpoutfile="${outfile}.$$"
function cleanup {
    rm -f "$tmpoutfile"
}
trap cleanup EXIT

cat <<EOF >"$tmpoutfile"
# HELP node_nic_firmware_version A metric with a constant '1' value with labels indicating NIC interface name, driver name, and firmware version string.
# TYPE node_nic_firmware_version gauge
EOF

# This mostly follows the logic from modules/base/lib/facter/net_driver.rb, but
# has some simplifications because we need fewer pieces of data.
cd /sys/class/net
for dev_driverlink in */device/driver/module ; do
    dev="$(echo "$dev_driverlink" | cut -f1 -d/)"
    driver="$(basename $(readlink $dev_driverlink))"
    # Quote any \s or "s with a \, then extract the firmware-version: value.
    firmware_version="$(ethtool -i "$dev" | sed -En 's!\\!\\\\!g; s!"!\\"!g; s/^firmware-version: (.*)$/\1/p')"
    echo "node_nic_firmware_version{device=\"$dev\",driver=\"$driver\",firmware_version=\"$firmware_version\"} 1" >>"$tmpoutfile"
done

mv "$tmpoutfile" "$outfile"
