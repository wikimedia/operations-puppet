#!/bin/sh
DEFAULT_FILE=/etc/default/haproxy
echo "ENABLED=1" > $DEFAULT_FILE

EXTRAOPTS=""

for file in $(ls -1 /etc/haproxy/conf.d); do
    EXTRAOPTS="${EXTRAOPTS} -f /etc/haproxy/conf.d/${file}"
done
echo "EXTRAOPTS=\"${EXTRAOPTS}\"" >> $DEFAULT_FILE
