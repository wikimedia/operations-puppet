#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

PROGNAME=$(basename "$0")
METRIC_FILE="/var/lib/prometheus/node.d/dpkg.prom"

print_usage() {
  echo "Usage: $PROGNAME"
}

print_help() {
  print_revision "$PROGNAME"
  echo ""
  print_usage
  echo ""
  echo "This plugin checks DPKG for packages that are in a wrong state."
  echo ""
  support
  exit 0
}

write_dpkg_success() {
  status="$1"
  cat > "$METRIC_FILE" <<EOF
# HELP node_dpkg_success Indicate whether dpkg is functioning
# TYPE node_dpkg_success gauge
node_dpkg_success $status
EOF
}

case "$1" in
  --help)
    print_help
    exit 0
    ;;
  -h)
    print_help
    exit 0
    ;;
  --version)
    print_revision "$PROGNAME"
    exit 0
    ;;
  -V)
    print_revision "$PROGNAME"
    exit 0
    ;;
  *)
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
    ;;
esac
