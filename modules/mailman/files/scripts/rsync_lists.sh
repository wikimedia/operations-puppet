#!/bin/bash
# rsync lists - T108071, T109399#1561586

INSTALL_DIR="/var/lib/mailman"
IMPORTED_DIRS=(archives lists qfiles)
RSYNC_TARGET="fermium.wikimedia.org/lists"

for MY_DIR in "${IMPORTED_DIRS[@]}"; do

    /usr/bin/rsync -avpz ${INSTALL_DIR}/${MY_DIR} rsync://${RSYNC_TARGET}

done

/usr/bin/rsync -avpz ${INSTALL_DIR}/data --include="heldmsg-*" --exclude="*.pw" --exclude="bounce-*" rsync://${RSYNC_TARGET}

echo "done rsyncing\n"
