#!/bin/bash

set -e
set -u

prometheus_path="/var/lib/prometheus/node.d/postgresql_replication_lag.prom"
pg_password=""
pg_master=""


function usage() {
  cat << EOF
Postgres replication lag for prometheus.

Options:

-m postgres master
-P postgres password
-p prometheus path
EOF
}

while getopts "D:hm:O:p:P:U:" opt; do
    case "$opt" in
    h)
        usage
        ;;
    m)
        pg_master=${OPTARG}
        ;;
    p)
        prometheus_path=${OPTARG}
        ;;
    P)
        pg_password=${OPTARG}
        ;;
    esac
done

lag_command="/usr/lib/nagios/plugins/check_postgres_replication_lag.py \
-U replication -P ${pg_password} -m ${pg_master} -D template1 --raw"

lag=`${lag_command}`

echo "postgresql_replication_lag" $lag > $prometheus_path.$$
mv $prometheus_path.$$ $prometheus_path
