#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
CERT_LIST_FILE=$1
if [ -z "$CERT_LIST_FILE" ]; then
    echo "ERR: no configuration file provided"
    exit 255
fi
if [ ! -e "$CERT_LIST_FILE" ]; then
    echo "ERR: \$CERT_LIST_FILE ($CERT_LIST_FILE) does not exist"
    exit 254
fi
# shellcheck source=/dev/null
. "$CERT_LIST_FILE"
if [ -z "$CERT_LIST" ]; then
    echo "ERR: \$CERT_LIST variable is empty, invalid config file?"
    exit 253
fi
EXIT_CODE=0
for cert in $CERT_LIST; do
    if [ ! -e "$cert" ]; then
        # Exit early if a certificate in the list doesn't exist
        echo "ERR: certificate $cert does not exist"
        exit 252
    fi
    # Check with openssl -checkend option
    # Using 0 seconds to verify if the certificate is already expired
    /usr/bin/openssl x509 -in "$cert" -checkend 0 -noout > /dev/null
    retval=$?
    if [ $retval -ne 0 ]; then
        echo "ERR: $cert is expired"
        EXIT_CODE=$((EXIT_CODE + 1))
    fi
done
exit $EXIT_CODE
