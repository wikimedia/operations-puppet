#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

PATH=/bin:/usr/bin
METRIC_FILE="/var/lib/prometheus/node.d/dpkg.prom"

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
  exit 0
fi

packagedata=$(dpkg -l | grep '^[uirph]' | grep -Ev '^(ii|rc)')
status=$?
if test "$1" = "-v" -o "$1" = "--verbose"; then
  echo "$packagedata"
fi
if test ${status} -eq 0 ; then
  echo "$packagedata" | grep -qv '^hi'
  if test $? -eq 1; then
    echo DPKG WARNING dpkg reports held packages
    write_dpkg_success 0
    exit 1
  fi
  echo DPKG CRITICAL dpkg reports broken packages
  write_dpkg_success 0
  exit 2
fi

echo All packages OK
write_dpkg_success 1
exit 0
