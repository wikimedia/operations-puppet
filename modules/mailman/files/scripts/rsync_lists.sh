#!/bin/bash
# rsync lists - T108071, T109399#1561586

/usr/bin/rsync -avz --delete /var/lib/mailman/lists/ rsync://fermium.wikimedia.org/lists

/usr/bin/rsync -avz --delete /var/lib/mailman/archives/ rsync://fermium.wikimedia.org/archives

/usr/bin/rsync -avz --delete /var/lib/mailman/archives/qfiles/ rsync://fermium.wikimedia.org/qfiles

/usr/bin/rsync -avz --delete /var/lib/mailman/data/ \
--include="heldmsg-*" \
--exclude="*.pw" \
--exclude="bounce-*" \
--exclude="sitelist.cfg" \
rsync://fermium.wikimedia.org/data

