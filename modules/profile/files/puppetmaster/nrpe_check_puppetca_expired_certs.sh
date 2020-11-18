#!/bin/bash
if [ $# -ne 3 ]
then
  echo -e "Usage:\n\t$0 WARN_SECS CRIT_SECS"
  exit 3
fi
signed_certs_dir=$1
warn=$2
crit=$3
exit_code=0
warn_nodes=()
warn_nodes=()
for node in "${signed_certs_dir}/"*.pem
do
  name="$(basename $node)"
  openssl x509 -in "${node}" -checkend "${crit}" &>/dev/null
  if [ $? -ne 0 ]
  then
    crit_nodes+=(${name%.*})
    continue
  fi
  openssl x509 -in "${node}" -checkend "${warn}" &>/dev/null || warn_nodes+=(${name%.*})
done
if [ ${#crit_nodes[@]} -ne 0 ]
then
  printf "CRITICAL | the puppet certs need to be renewed:\ncrit: %s\nwarn: %s\n" "${crit_nodes[*]}" "${warn_nodes[*]}"
  exit 2
fi
if [ ${#warn_nodes[@]} -ne 0 ]
then
  printf "WARN | the puppet certs need to be renewed:\nwarn: %s\n" "${warn_nodes[*]}"
  exit 1
fi
printf 'OK | all puppet agent certs fine\n'
exit 0

