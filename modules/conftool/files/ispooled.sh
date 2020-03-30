#!/bin/sh
# ispooled -- exit 0 if the given service is pooled

if [ -z "$1" ]; then
        echo "Usage: $0 servicename"
        exit 1
fi

hostname="$(/bin/hostname --fqdn)"

/usr/bin/confctl select name="${hostname}",service=$1 get |
        /usr/bin/jq ".[\"${hostname}\"].pooled" | /bin/grep -q '"yes"'
