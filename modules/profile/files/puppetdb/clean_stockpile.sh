#!/bin/sh
PATH=/usr/bin
MAX_SIZE=1000000 # 1GB
QUEUE='/var/lib/puppetdb/stockpile/cmd/q'
if [ "$(df  --output='used' "${QUEUE}" | sed 1d)" -gt "${MAX_SIZE}" ]
then
  printf '%s: cleaning %s\\n' "$(date)" "${QUEUE}"
  find "${QUEUE}" -type f -delete
fi
