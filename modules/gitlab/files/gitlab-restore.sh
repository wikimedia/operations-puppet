#!/usr/bin/env bash

LOGFILE=/var/log/gitlab-restore-backup.log

echo "Running Pre-requisites..." >> $LOGFILE

# Create Backup Configuration Files
CONFIG_FILE=/etc/gitlab/gitlab.rb
SECRETS_FILE=/etc/gitlab/gitlab-secrets.json

if [ -f "$CONFIG_FILE" ] && [ -f "$SECRETS_FILE" ]; then
    /usr/bin/echo "Creating backup of $CONFIG_FILE and $SECRETS_FILE" >> $LOGFILE
    /usr/bin/cp $CONFIG_FILE $CONFIG_FILE.bak
    /usr/bin/cp $SECRETS_FILE $SECRETS_FILE.bak
else
    /usr/bin/echo "Configuration File: $CONFIG_FILE Not Found" >> $LOGFILE
    exit 1
fi

OLD_BACKUP_FILE=/srv/gitlab-backup/latest/latest.tar
NEW_BACKUP_FILE=/srv/gitlab-backup/latest_gitlab_backup.tar
if [ -f "$OLD_BACKUP_FILE" ]; then
    echo "Moving $OLD_BACKUP_FILE to $NEW_BACKUP_FILE"  >> $LOGFILE
    /usr/bin/cp $OLD_BACKUP_FILE $NEW_BACKUP_FILE  >> $LOGFILE
else
    echo "Backup File $OLD_BACKUP_FILE Not Found"  >> $LOGFILE
    exit 1
fi


CONFIG_BACKUP=/etc/gitlab/config_backup/latest/latest.tar

# Change Permissions
echo "changing permissions - chmod 600"  >> $LOGFILE
/usr/bin/chmod 600 $NEW_BACKUP_FILE $CONFIG_BACKUP


# Extract Configuration Backup
/usr/bin/tar -xvf $CONFIG_BACKUP --strip-components=2 -C /etc/gitlab/
if [ -f $CONFIG_FILE.bak ] && [ -f "$SECRETS_FILE" ]; then
    echo "Reverting configuration files to those of the replica..." >> $LOGFILE
    /usr/bin/cp $CONFIG_FILE.bak $CONFIG_FILE
    /usr/bin/cp $SECRETS_FILE.bak $SECRETS_FILE
else
    echo "Configuration backup files $CONFIG_FILE.bak $SECRETS_FILE.bak not found" >> $LOGFILE
    exit
fi

echo "running gitlab-ctl reconfigure" >> $LOGFILE
/usr/bin/gitlab-ctl reconfigure >> $LOGFILE
/usr/bin/gitlab-ctl status

/usr/bin/systemctl stop ssh-gitlab
if [[ $? -ne 0 ]]; then
    echo "something went wrong stopping ssh-gitlab" >> $LOGFILE
    exit 1
fi

# just a sanity check to see if the service is not running
SSH_GITLAB_STATUS=$(/usr/bin/systemctl show -p SubState --value ssh-gitlab)
if [ "${SSH_GITLAB_STATUS}" = "running" ]; then
    echo "ssh-gitlab service still running. please kill it before proceeding" >> $LOGFILE
    exit 1
fi

if /usr/bin/gitlab-ctl stop puma && /usr/bin/gitlab-ctl stop sidekiq; then
    echo "stopped puma & sidekiq service" >> $LOGFILE
else
    echo "something went wrong stopping /usr/bin/gitlab-ctl services" >> $LOGFILE
fi


/usr/bin/gitlab-ctl status | grep "down: puma" &> /dev/null
if [ $? == 0 ]; then
   echo "puma service stopped" >> $LOGFILE
else
    echo "puma service still running" >> $LOGFILE
    exit 1
fi

/usr/bin/gitlab-ctl status | grep "down: sidekiq" &> /dev/null
if [ $? == 0 ]; then
   echo "sidekiq service stopped" >> $LOGFILE
else
    echo "sidekiq service still running" >> $LOGFILE
    exit 1
fi

echo "running gitlab-backup restore"
BACKUP=latest
/usr/bin/gitlab-backup restore GITLAB_ASSUME_YES=1 BACKUP=$BACKUP >> $LOGFILE
if [ $? == 0 ]; then
   echo "Successfully Restored Backup: $BACKUP" >> $LOGFILE
else
   echo "Something Went Wrong Restoring Backup: $BACKUP" >> $LOGFILE
   exit 1
fi

echo "running gitlab-ctl reconfigure"
/usr/bin/gitlab-ctl reconfigure

echo "running gitlab-ctl restart"
/usr/bin/gitlab-ctl restart

/usr/bin/gitlab-ctl status | grep "run: puma" &> /dev/null
if [ $? == 0 ]; then
   echo "puma service running" >> $LOGFILE
else
    echo "puma service not running" >> $LOGFILE
    exit 1
fi

/usr/bin/gitlab-ctl status | grep "run: sidekiq" &> /dev/null
if [ $? == 0 ]; then
   echo "sidekiq service running" >> $LOGFILE
else
    echo "sidekiq service not running" >> $LOGFILE
    exit 1
fi

/usr/bin/gitlab-rake gitlab:check SANITIZE=true >> $LOGFILE
/usr/bin/gitlab-rake gitlab:doctor:secrets >> $LOGFILE

echo "ApplicationSetting.last.update(home_page_url: 'https://gitlab-replica.wikimedia.org/explore')" | /usr/bin/gitlab-rails console >> $LOGFILE

/usr/bin/systemctl restart ssh-gitlab