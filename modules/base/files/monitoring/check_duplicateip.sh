#!/bin/bash

if [[ ${#} -ne "2" ]]; then
    echo "Wrong number of parameters"
    exit 3
fi

arping_result=$(/usr/sbin/arping -i "${1}" -c 1 -C 1 "${2}" -S 0.0.0.0 -r)

if [[ "${?}" -eq "0" ]]; then # We got a reply
  echo "ARP reply from MAC $arping_result"
  exit 2
elif [[ "${?}" -eq "1" ]]; then # No reply
  echo "No ARP reply for primary IP"
  exit 0
else
  echo "Unknown result"
  exit 3
fi
