#!/bin/bash
#- SPDX-License-Identifier: Apache-2.0
set -o nounset
set -o pipefail
set -o errexit

prom_file="/var/lib/prometheus/node.d/prom_k8s_nfs_stuck.prom"


stuck_processes="$(ps -eo state,user:50,cmd | grep '^D')" || :
maybe_total_stuck="$(echo "$stuck_processes" | wc -l)"
total_stuck=0
is_lsof_stuck="$(echo "$stuck_processes" | grep '^D.*/usr/bin/lsof')" || :

if [[ "$is_lsof_stuck" != "" ]]; then
    total_stuck="$maybe_total_stuck"
fi

cat >"$prom_file" <<EOP
# HELP prometheus_k8s_nfs_stuck_procs_total Number of processes stuck on NFS
# TYPE prometheus_k8s_nfs_stuck_procs_total gauge
prometheus_k8s_nfs_stuck_total_procs $total_stuck
# HELP prometheus_k8s_nfs_stuck_procs_per_tool Number of processes stuck on NFS per tool
# TYPE prometheus_k8s_nfs_stuck_procs_per_tool gauge
EOP

if [[ "$is_lsof_stuck" != "" ]]; then
    echo "$stuck_processes" \
        | grep -o 'tools\.[^ ]*' \
        | sort \
        | uniq -c \
        | sed -e 's/tools\./tool-/g' \
        | awk '{print "prometheus_k8s_nfs_stuck_procs_per_tool{tool=\""  $2 "\"} " $1}' \
    >> "$prom_file"
fi
