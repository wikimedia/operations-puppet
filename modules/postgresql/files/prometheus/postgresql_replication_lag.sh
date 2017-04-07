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

while getopts "hm:p:P:" opt; do
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
    *)
        usage
        exit 1
        ;;
    esac
done

lag="$(/usr/bin/check_postgres_hot_standby_delay \
--host="${pg_master}",localhost \
--dbuser=replication --dbpass="${pg_password}" -dbname=template1)"

echo "postgresql_replication_lag_bytes ${lag}" > ${prometheus_path}.$$
mv ${prometheus_path}.$$ ${prometheus_path}
