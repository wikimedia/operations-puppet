#!/bin/sh
# rsync lists - T108071, T109399#1561586

/usr/bin/rsync -avz --delete /var/lib/mailman/lists/ rsync://lists1001.wikimedia.org/lists

/usr/bin/rsync -avz --delete /var/lib/mailman/archives/ rsync://lists1001.wikimedia.org/archives

/usr/bin/rsync -avz --delete /var/lib/mailman/qfiles/ rsync://lists1001.wikimedia.org/qfiles

/usr/bin/rsync -avz --delete /var/lib/mailman/data/ \
--include="heldmsg-*" \
--exclude="*.pw" \
--exclude="bounce-*" \
--exclude="sitelist.cfg" \
rsync://lists1001.wikimedia.org/data

