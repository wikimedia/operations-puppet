#!/bin/bash
# import exim mail queue locally
# T110138

IMPORT_DIR="/var/lib/mailman/import"
SPOOL_DIR="/var/spool/exim4"
INSTALL_USER="Debian-exim"

 rsync -avp ${IMPORT_DIR}/exim/input/ ${SPOOL_DIR}/input/
 chown ${INSTALL_USER}:${INSTALL_USER} ${SPOOL_DIR}/input*

 rsync -avp ${IMPORT_DIR}/exim/input/ ${SPOOL_DIR}/msglog/
 chown ${INSTALL_USER}:${INSTALL_USER} ${SPOOL_DIR}/msglog*

