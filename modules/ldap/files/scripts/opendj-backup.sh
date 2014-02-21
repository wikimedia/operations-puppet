#!/bin/bash

#####################################################################
### THIS FILE IS MANAGED BY PUPPET 
### puppet:///modules/ldap/scripts/opendj-backup.sh
#####################################################################

# LDAP backups shouldn't be readable by all
umask 027

BACKUPDIR="/var/opendj/backups"
if [ ! -d "${BACKUPDIR}" ]
then
	mkdir ${BACKUPDIR}
fi
INSTANCEDIR="/var/opendj/instance"
DATE=`date +%F`
CURRENTBACKUPDIR="${BACKUPDIR}/backup-${DATE}"

mkdir $CURRENTBACKUPDIR

# Backup all instance backends, the config file, and all logs.
# Logs are necessary for restores, according to the documentation.
/usr/opendj/bin/backup --backUpAll --compress --backupDirectory $CURRENTBACKUPDIR
cp ${INSTANCEDIR}/config/config.ldif $CURRENTBACKUPDIR
cp -R ${INSTANCEDIR}/logs $CURRENTBACKUPDIR
tar -cjvf ${BACKUPDIR}/opendj-backup-${DATE}.tar.bz2 $CURRENTBACKUPDIR

rm -Rf $CURRENTBACKUPDIR

# Remove any backups older than a day. We are doing daily full
# backups. No need to keep more then a day of backups around.
find ${BACKUPDIR} -type f -mtime +1 -exec rm -f {} \;
