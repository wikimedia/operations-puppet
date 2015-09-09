#!/bin/bash
# rsync lists - T108071, T109399#1561586

/usr/bin/rsync -avzc --delete /var/lib/mailman/lists/ rsync://fermium.wikimedia.org/lists

/usr/bin/rsync -avzc --delete /var/lib/mailman/archives/ rsync://fermium.wikimedia.org/archives

/usr/bin/rsync -avzc --delete /var/lib/mailman/data/ \
--include="heldmsg-*" \
--exclude="*.pw" \
--exclude="bounce-*" \
--exclude="sitelist.cfg" \
--exclude="last_mailman_version" \
rsync://fermium.wikimedia.org/data

