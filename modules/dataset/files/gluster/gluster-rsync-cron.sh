#!/bin/bash
running=`pgrep -u root -f   'python /root/wmfdumpsmirror.py --remotedir /data/xmldatadumps/public'`
if [ -z "$running" ]; then
    python /usr/local/bin/wmfdumpsmirror.py --remotedir /data/xmldatadumps/public --localdir /mnt/glusterpublicdata/public --filesperjob 50 --sizeperjob 5G --workercount 3 --rsynclist rsync-list.txt.rsync
fi
running=`pgrep -u root -f -x  '/usr/bin/rsync -a /data/xmldatadumps/public/other/incr /mnt/glusterpublicdata/public/other/'`
if [ -z "$running" ]; then
    /usr/bin/rsync -a /data/xmldatadumps/public/other/incr /mnt/glusterpublicdata/public/other/
fi
running=`pgrep -u root -f -x '/usr/bin/rsync -a /data/xmldatadumps/public/other/pagecounts-raw labnfs.pmtpa.wmnet::pagecounts`
if [ -z "$running" ]; then
    /usr/bin/rsync -a /data/xmldatadumps/public/other/pagecounts-raw labnfs.pmtpa.wmnet::pagecounts
fi
