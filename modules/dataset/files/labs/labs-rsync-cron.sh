#!/bin/bash
running=`pgrep -u root -f   'python /root/wmfdumpsmirror.py --remotedir /data/xmldatadumps/public'`

if [ -d /mnt/dumps/lost+found ]; then

    if [ -z "$running" ]; then
        python /usr/local/bin/wmfdumpsmirror.py --remotedir /data/xmldatadumps/public --localdir /mnt/dumps/public --filesperjob 50 --sizeperjob 5G --workercount 1 --rsynclist rsync-filelist-last-2-good.txt.rsync --rsyncargs -rlptq
    fi
    running=`pgrep -u root -f -x  '/usr/bin/rsync -rlpt /data/xmldatadumps/public/other/incr /mnt/dumps/'`
    if [ -z "$running" ]; then
        /usr/bin/rsync -rlpt /data/xmldatadumps/public/other/incr /mnt/dumps/
    fi
    running=`pgrep -u root -f -x '/usr/bin/rsync -rlpt /data/xmldatadumps/public/other/pagecounts-raw /mnt/dumps/'`
    if [ -z "$running" ]; then
        /usr/bin/rsync -rlpt /data/xmldatadumps/public/other/pagecounts-raw /mnt/dumps/
    fi

else
    echo "$0: mount doesn't appear there.  Bailing out!" >&2
    exit 1
fi
