#!/usr/bin/bash
# Author: Damian Zaremba <damian@damianzaremba.co.uk>
# 
# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What The Fuck You Want
# To Public License, Version 2, as published by Sam Hocevar. See
# http://sam.zoy.org/wtfpl/COPYING for more details.

# Ensure the target dir exists
BACKUP_DIR="/data/project/backups/mysql/$(hostname -f)"
test -d $BACKUP_DIR || mkdir -p $BACKUP_DIR

# Take the dump
mysqldump -uroot -ppuppet -A > $BACKUP_DIR/$(date +"%d-%m-%Y_%H-%M-%S").sql

# Clean up old dumps over 2 weeks old
find $BACKUP_DIR -type f -mtime +15 -exec rm -vf {} \;
