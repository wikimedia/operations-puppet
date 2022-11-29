#!/bin/bash

set -e
set -u

service=${1}
reload_opts=${*:2}
substate=$(systemctl show --value --property SubState "${service}")
icinga_file="${ICINGA_FILE:-/var/run/reload-vcl-state}"
prom_file="${PROM_FILE:-/var/lib/prometheus/node.d/confd-reload-vcl.prom}"

if [ "${substate}" != "running" ]; then
    echo "${service} is not running"
    exit 0
fi

# Need to pass distinct arguments, don't quote
# shellcheck disable=SC2086
if /usr/local/sbin/reload-vcl ${reload_opts}; then
    state=1
else
    state=0
fi

echo ${state} > "${icinga_file}"

cat <<EOF > "${prom_file}.$$"
# HELP confd_vcl_reload_success Whether a vcl reload by confd was successful
# TYPE confd_vcl_reload_success gauge
confd_vcl_reload_success ${state}
EOF
mv "${prom_file}.$$" "${prom_file}"
