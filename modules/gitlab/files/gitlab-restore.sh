#!/usr/bin/env bash

LOGFILE=/var/log/gitlab-restore-backup.log
CONFIG_FILE=/etc/gitlab/gitlab.rb
OLD_BACKUP_FILE=/mnt/gitlab-backup/latest/latest.tar
NEW_BACKUP_FILE=/mnt/gitlab-backup/latest_gitlab_backup.tar
CONFIG_BACKUP=/etc/gitlab/config_backup/latest/latest.tar

# check if installed GitLab version matches backup version
installed_version=$(dpkg -l gitlab-ce | grep -Po "\\d*\.\\d*\.\\d*")
backup_version=$(tar -axf $OLD_BACKUP_FILE backup_information.yml -O | grep gitlab_version  | grep -Po "\\d*\.\\d*\.\\d*")

if [ $installed_version != $backup_version ]; then
    /usr/bin/echo "Installed GitLab version $installed_version doesn't match backup GitLab version $backup_version" >> $LOGFILE
    exit 1
fi

# disable puppet to prevent stopped services from restart
# during the backup restoration process
/usr/local/sbin/disable-puppet "Running Backup Restore"

echo "Running Pre-requisites..." >> $LOGFILE

# Create Backup Configuration Files

if [ -f "$CONFIG_FILE" ]; then
    /usr/bin/echo "Creating backup of $CONFIG_FILE" >> $LOGFILE
    /usr/bin/cp $CONFIG_FILE $CONFIG_FILE.restore
else
    /usr/bin/echo "Configuration File: $CONFIG_FILE Not Found" >> $LOGFILE
    exit 1
fi

if [ -f "$OLD_BACKUP_FILE" ]; then
    echo "Moving $OLD_BACKUP_FILE to $NEW_BACKUP_FILE"  >> $LOGFILE
    /usr/bin/cp $OLD_BACKUP_FILE $NEW_BACKUP_FILE  >> $LOGFILE
else
    echo "Backup File $OLD_BACKUP_FILE Not Found"  >> $LOGFILE
    exit 1
fi

# Change Permissions
echo "changing access permissions of backups"  >> $LOGFILE
/usr/bin/chmod 600 $NEW_BACKUP_FILE $CONFIG_BACKUP
/usr/bin/chown git.git $NEW_BACKUP_FILE $CONFIG_BACKUP

# Extract Configuration Backup
/usr/bin/tar -xvf $CONFIG_BACKUP --strip-components=2 -C /etc/gitlab/
if [ -f $CONFIG_FILE.restore ]; then
    echo "Reverting configuration files to those of the replica..." >> $LOGFILE
    /usr/bin/cp $CONFIG_FILE.restore $CONFIG_FILE
else
    echo "Configuration backup files $CONFIG_FILE.restore not found" >> $LOGFILE
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

for i in {1..10}; do
    echo "ApplicationSetting.last.update(home_page_url: 'https://gitlab-replica.wikimedia.org/explore')" | /usr/bin/gitlab-rails console >> $LOGFILE && break || sleep 15
done

/usr/bin/systemctl restart ssh-gitlab

/usr/local/sbin/enable-puppet "Running Backup Restore"
