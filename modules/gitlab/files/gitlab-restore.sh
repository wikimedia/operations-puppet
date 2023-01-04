#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

LOGFILE=/var/log/gitlab-restore-backup.log
CONFIG_FILE=/etc/gitlab/gitlab.rb
DATA_BACKUP_FILE=$(ls -t /srv/gitlab-backup/*gitlab_backup.tar | head -n1)
CONFIG_BACKUP_FILE=$(ls -t /srv/gitlab-backup/gitlab_config*.tar | head -n1)

# check if installed GitLab version matches backup version
installed_version=$(dpkg -l gitlab-ce | grep -Po "\\d*\.\\d*\.\\d*")
backup_version=$(tar -axf $DATA_BACKUP_FILE backup_information.yml -O | grep gitlab_version  | grep -Po "\\d*\.\\d*\.\\d*")

if [ $installed_version != $backup_version ]; then
    /usr/bin/echo "Installed GitLab version $installed_version doesn't match backup GitLab version $backup_version" >> $LOGFILE
    exit 1
fi

# disable puppet to prevent stopped services from restart
# during the backup restoration process
/usr/local/sbin/disable-puppet "Running Backup Restore"

echo "Running Pre-requisites..." >> $LOGFILE

# Check if backup files exist
if [ ! -f "$CONFIG_BACKUP_FILE" ]; then
    /usr/bin/echo "Configuration File: $CONFIG_BACKUP_FILE Not Found" >> $LOGFILE
    exit 1
fi

if [ ! -f "$DATA_BACKUP_FILE" ]; then
    echo "Backup File $DATA_BACKUP_FILE Not Found"  >> $LOGFILE
    exit 1
fi

# Change Permissions
echo "changing access permissions of backups"  >> $LOGFILE
/usr/bin/chmod 600 $DATA_BACKUP_FILE $CONFIG_BACKUP_FILE
/usr/bin/chown git.git $DATA_BACKUP_FILE $CONFIG_BACKUP_FILE

# Extract Configuration Backup
/usr/bin/tar -xvf $CONFIG_BACKUP_FILE --exclude='/etc/gitlab/gitlab.rb*' --strip-components=2 -C /etc/gitlab/

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

if /usr/bin/gitlab-ctl graceful-kill puma && /usr/bin/gitlab-ctl stop sidekiq; then
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
BACKUP=$(basename $DATA_BACKUP_FILE | sed 's/_gitlab_backup.tar//') #GitLab referes to the timestamp, not full file names
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

for i in {1..10}; do
    echo "ApplicationSetting.last.update(home_page_url: 'https://gitlab-replica.wikimedia.org/explore')" | /usr/bin/gitlab-rails console >> $LOGFILE && break || sleep 15
done

/usr/bin/systemctl restart ssh-gitlab

/usr/local/sbin/enable-puppet "Running Backup Restore"
