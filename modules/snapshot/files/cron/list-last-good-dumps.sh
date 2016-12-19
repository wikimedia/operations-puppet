#!/bin/bash
#############################################################
# This file is maintained by puppet!
# /modules/snapshot/cron/list-last-good-dumps.sh
#############################################################

source /usr/local/etc/set_dump_dirs.sh

# generate lists of most recent completed successful dumps for rsync (dirs, files)
python /usr/local/bin/list-last-n-good-dumps.py --dumpsnumber 1,2,3,4,5 --dirlisting 'rsync-dirlist-last-%s-good.txt' --configfile "${confsdir}/wikidump.conf.monitor" --rsynclists --relpath --outputdir "${datadir}/public/"
python /usr/local/bin/list-last-n-good-dumps.py --dumpsnumber 1,2,3,4,5 --filelisting 'rsync-filelist-last-%s-good.txt' --configfile "${confsdir}/wikidump.conf.monitor" --rsynclists --relpath --outputdir "${datadir}/public/" --toplevel
# these lists can be used for rsync excl/incl on our side, providing shares that "just work" for the mirrors
python /usr/local/bin/list-last-n-good-dumps.py --dumpsnumber 1,2,3,4,5 --rsynclisting 'rsync-inc-last-%s.txt' --configfile "${confsdir}/wikidump.conf.monitor" --relpath --outputdir "${datadir}/public/" --toplevel
