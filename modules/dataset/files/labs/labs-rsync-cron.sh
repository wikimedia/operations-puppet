#!/bin/bash
running=`pgrep -u root -f   'python /root/wmfdumpsmirror.py --remotedir /data/xmldatadumps/public'`
if [ -z "$running" ]; then
    python /usr/local/bin/wmfdumpsmirror.py --remotedir /data/xmldatadumps/public --localdir /mnt/dumps/public --filesperjob 50 --sizeperjob 5G --workercount 3 --rsynclist rsync-list.txt.rsync
fi
running=`pgrep -u root -f -x  '/usr/bin/rsync -a /data/xmldatadumps/public/other/incr /mnt/dumps/incr/'`
if [ -z "$running" ]; then
    /usr/bin/rsync -a /data/xmldatadumps/public/other/incr /mnt/dumps/incr/
fi
running=`pgrep -u root -f -x '/usr/bin/rsync -a /data/xmldatadumps/public/other/pagecounts-raw /mnt/dumps/pagecounts'`
if [ -z "$running" ]; then
    /usr/bin/rsync -a /data/xmldatadumps/public/other/pagecounts-raw /mnt/dumps/pagecounts
fi
