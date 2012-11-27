#!/bin/bash
BASEDIR=/root/backups
if [ -f "$BASEDIR/uploaddirs.txt" ]; then
    cp -p "$BASEDIR/uploaddirs.txt" "$BASEDIR/uploaddirs.txt.old"
fi
cd "$BASEDIR"
wget -q -N "http://download.wikimedia.org/other/imageinfo/uploaddirs.txt"
if [ $? -ne 0 ]; then
    echo "Failed to retrieve upload directory listing. Exiting early."
    exit 1
fi
RUNNING=`/usr/bin/pgrep rsyncmedia.py`
if [ -z "$RUNNING"]; then
	python "$BASEDIR/rsyncmedia.py" --remotedir /mnt --localdir /export/upload --wikilist "$BASEDIR/uploaddirs.txt" --big enwiki --huge commonswiki
else
	echo "Previous rsyncmedia.py ($RUNNING) already running."
fi
