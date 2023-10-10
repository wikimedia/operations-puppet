#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

PATH=/bin:/usr/bin

METRIC_FILE="${1:-/var/lib/prometheus/node.d/dpkg.prom}"

write_dpkg_success() {
  status="$1"
  cat > "$METRIC_FILE" <<EOF
# HELP node_dpkg_success Indicate whether dpkg is functioning
# TYPE node_dpkg_success gauge
node_dpkg_success $status
EOF
}

if fuser -s /var/lib/dpkg/lock ; then
  echo "dpkg is running, not checking broken packages"
  write_dpkg_success 1
  exit
fi

packagedata=$(dpkg -l | grep '^[uirph]' | grep -Ev '^(ii|rc)')
status=$?
if test ${status} -eq 0 ; then
  echo "$packagedata" | grep -qv '^hi'
  if test $? -eq 1; then
    echo DPKG WARNING dpkg reports held packages
    write_dpkg_success 0
    exit
  fi
  echo DPKG CRITICAL dpkg reports broken packages
  write_dpkg_success 0
  exit
fi

echo All packages OK
write_dpkg_success 1
exit

