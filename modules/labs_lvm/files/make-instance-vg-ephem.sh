#!/bin/bash
set -euo pipefail

while read line; do
  if [[ "$line" =~ "ephemeral" ]]; then
    ephemeral=$(echo "$line" | cut -d' ' -f1)
    ephemeraldev="/dev/$ephemeral"
    break
  fi
done < <(lsblk -oname,label -dn)

if [ -z "${ephemeraldev}" ]; then
    echo "$0: did not find ephemeral disk" >&2
    exit 1
fi

/sbin/pvcreate -f "$ephemeraldev"
/sbin/vgcreate vd "$ephemeraldev"
