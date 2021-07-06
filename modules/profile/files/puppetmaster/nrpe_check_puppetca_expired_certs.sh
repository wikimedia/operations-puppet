#!/bin/bash
if [ $# -ne 3 ]
then
  printf "Usage:\\n\\t%s WARN_SECS CRIT_SECS\\n" %0
  exit 3
fi
signed_certs_dir=$1
warn=$2
crit=$3
warn_nodes=()
warn_nodes=()
for node in "${signed_certs_dir}/"*.pem
do
  name="$(basename "${node%.*}")"
  if ! openssl x509 -in "${node}" -checkend "${crit}" &>/dev/null
  then
    crit_nodes+=( "$name" )
    continue
  fi
  openssl x509 -in "${node}" -checkend "${warn}" &>/dev/null || warn_nodes+=( "$name" )
done
if [ ${#crit_nodes[@]} -ne 0 ]
then
  printf "CRITICAL: %d puppet certs need to be renewed:\\ncrit: %s\\nwarn: %s\\n" ${#crit_nodes[@]} "${crit_nodes[*]}" "${warn_nodes[*]}"
  exit 2
fi
if [ ${#warn_nodes[@]} -ne 0 ]
then
  printf "WARN:  %d puppet certs need to be renewed:\\nwarn: %s\\n" ${#crit_nodes[@]} "${warn_nodes[*]}"
  exit 1
fi
printf 'OK:  all puppet agent certs fine\n'
exit 0

