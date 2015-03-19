#!/bin/bash
#
# This fetches and validates an OCSP response for a cert, creating/updating a
# file named /var/ssl/ocsp/${CERT_NAME}.ocsp which can be used with the nginx
# ssl_stapling_file directive.
#
# The sole argument is the ${CERT_NAME}, which should match an input certificate
# stored at /etc/ssl/localcerts/${CERT_NAME}.crt.
#
# If any step of this process fails, a temporary output dir may be left behind
# at a pathname like /var/ssl/ocsp/ocsp.tmp.XXXXXXXX, where the X are random.
#
# If the date range check was the source of failure, there should be a file
# named ${CERT_NAME}.ocsp within, which can be decoded with ...
#     openssl ocsp -respin $tempfile -resp_text
# ... to see why the request may have failed (compare various timestamps with
# the creation timestamp of the file).
#

# Fail fast on any subcommand failure, to avoid clobbering a good OCSP file
set -e
set -o pipefail

# Input args
CERT_NAME=$1

# Basic variables / constants
THISUP_FUTURE_OFFSET="1 minute"
NEXTUP_FUTURE_OFFSET="1 hour"
CERT_DIR=/etc/ssl/localcerts
ISSUER_DIR=/etc/ssl/certs
OUT_DIR=/var/ssl/ocsp
CERT_PATH=${CERT_DIR}/${CERT_NAME}.crt

# umask / directories / output pathnames
umask 022
mkdir -p $OUT_DIR
OUT_DIR_TEMP=$(mktemp -d ${OUT_DIR}/ocsp.tmp.XXXXXXXX)
OUT_TEMP=${OUT_DIR_TEMP}/${CERT_NAME}.ocsp
OUT_FINAL=${OUT_DIR}/${CERT_NAME}.ocsp

# Fetch the OCSP URL and the Issuer Hash from the cert
OCSP_URL=$(openssl x509 -in ${CERT_PATH} -noout -ocsp_uri 2>/dev/null)
ISSUER_PATH="${ISSUER_DIR}/$(openssl x509 -in ${CERT_PATH} -noout -issuer_hash 2>/dev/null).0"

# actual ocsp fetch, outputs to temporary file
openssl ocsp -nonce -respout ${OUT_TEMP} -issuer ${ISSUER_PATH} -cert ${CERT_PATH} -path $OCSP_URL -host webproxy.esams.wmnet:8080 >/dev/null 2>&1

# Validate thisUpdate/nextUpdate window
OCSP_TEXT=$(openssl ocsp -noverify -respin ${OUT_TEMP} -resp_text)
THISUP_RAW=$(echo "$OCSP_TEXT" | grep -i 'This Update:' | cut -d: -f2-)
NEXTUP_RAW=$(echo "$OCSP_TEXT" | grep -i 'Next Update:' | cut -d: -f2-)
THISUP_UNIX=$(date -d "$THISUP_RAW" +%s)
NEXTUP_UNIX=$(date -d "$NEXTUP_RAW" +%s)
THISUP_CMP=$(date -d "+${THISUP_FUTURE_OFFSET}" +%s)
NEXTUP_CMP=$(date -d "+${NEXTUP_FUTURE_OFFSET}" +%s)
if [ $THISUP_UNIX -gt $THISUP_CMP ]; then
    echo "Failing; thisUpdate is greater than ${THISUP_FUTURE_OFFSET} into the future"
    exit 1
fi
if [ $NEXTUP_UNIX -lt $NEXTUP_CMP ]; then
    echo "Failing; nextUpdate is less than ${NEXTUP_FUTURE_OFFSET} into the future"
    exit 1
fi

# Move new OCSP response into path for nginx pickup
mv -f ${OUT_TEMP} ${OUT_FINAL}

# clean up temporary dir
rmdir ${OUT_DIR_TEMP}
