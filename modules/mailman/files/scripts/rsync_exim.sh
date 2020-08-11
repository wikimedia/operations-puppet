#!/bin/bash
# rsync exim queue - T110138

SPOOL_DIR="/var/spool/exim4"
RSYNC_TARGET="lists1001.wikimedia.org/exim"

/usr/bin/rsync -avp ${SPOOL_DIR}/ \
--exclude="db" \
--exclude="exim-process.info" \
--exclude="gnutls-params" \
--exclude="scan" \
rsync://${RSYNC_TARGET}

