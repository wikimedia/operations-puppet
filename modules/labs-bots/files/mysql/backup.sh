#!/usr/bin/bash
# Author: Damian Zaremba <damian@damianzaremba.co.uk>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# Ensure the target dir exists
BACKUP_DIR="/data/project/backups/mysql/$(hostname -f)"
test -d $BACKUP_DIR || mkdir -p $BACKUP_DIR

# Take the dump
mysqldump -uroot -ppuppet -A > $BACKUP_DIR/$(date +"%d-%m-%Y_%H-%M-%S").sql

# Clean up old dumps over 2 weeks old
find $BACKUP_DIR -type f -mtime +15 -exec rm -vf {} \;
