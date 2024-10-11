#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

set -eu
set -o pipefail

outfile="$(realpath "${1:-/var/lib/prometheus/node.d/kernel-panic.prom}")"
tmpoutfile="${outfile}.$$"
function cleanup {
    rm -f "$tmpoutfile"
}
trap cleanup EXIT

if [ "$(id -u)"  != "0" ] ; then
    echo "root required!" >&2
    exit 1
fi

# try to detect older messages in case of a reboot or if the node was down for whatever reason
SINCE="30m ago"

# instead of _TRANSPORT=kernel we could be using '--dmesg --boot=all'
# if all servers were >= buster, but they aren't as of this writing
journal=$(journalctl --quiet _TRANSPORT=kernel --since "${SINCE}")
panic=$(grep --count "\[ cut here \]" <<< "${journal}" || :)
warning=$(grep --ignore-case --count "warning" <<< "${journal}" || :)
taint=$(grep --ignore-case --count "taint" <<< "${journal}" || :)

err_prio=$(journalctl --quiet _TRANSPORT=kernel --since "${SINCE}" --priority=err | wc -l)

cat <<EOF >"$tmpoutfile"
# HELP kernel_dmesg_panic Number of kernel panic messages since ${SINCE}
# TYPE kernel_dmesg_panic gauge
kernel_dmesg_panic ${panic}
# HELP kernel_dmesg_warning Number of kernel warning messages since ${SINCE}
# TYPE kernel_dmesg_warning gauge
kernel_dmesg_warning ${warning}
# HELP kernel_dmesg_taint Number of kernel taint messages since ${SINCE}
# TYPE kernel_dmesg_taint gauge
kernel_dmesg_taint ${taint}
# HELP kernel_dmesg_err_priority Number of kernel messages with the err priority since ${SINCE}
# TYPE kernel_dmesg_err_priority gauge
kernel_dmesg_err_priority ${err_prio}
EOF

mv "$tmpoutfile" "$outfile"
chmod a+r "$outfile"
