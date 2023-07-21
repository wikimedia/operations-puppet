#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
PATH=/usr/bin

yellow='\e[0;33m'
reset='\e[m'
find /run -mindepth 1 -maxdepth 2 -type f -name restart_required | while read -r line
do
  IFS='/' read -ra path_parts <<< "$line"
  printf '%b%s needs restarting check %s%b\n' "${yellow}" "${path_parts[2]}" "$line" "${reset}"
done
