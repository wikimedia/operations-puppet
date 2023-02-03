#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

# Disable puppet to prevent stopped services from restart
# during the backup restoration process
/usr/local/sbin/disable-puppet "Running Backup Restore"

LOGFILE=/var/log/gitlab-restore-backup.log

DEFAULT_BACKUP_FILE=$(ls -t /srv/gitlab-backup/*gitlab_backup.tar | head -n1)
CONFIG_BACKUP_FILE=$(ls -t /srv/gitlab-backup/gitlab_config*.tar | head -n1)
KEEP_CONFIG="false"
REQUESTED_BACKUP=""
GITLAB_URL=$(grep '^external_url ' /etc/gitlab/gitlab.rb | cut -d '"' -f2)

usage() {
  /usr/bin/echo "Usage: $0 [ -f REQUESTED_BACKUP ] [ -k KEEP_CONFIG]" 1>&2
}

exit_error() {
    usage
    exit 1
}

while getopts ":f:k:" options; do
    case "${options}" in
         f)
         REQUESTED_BACKUP=${OPTARG}
         ;;
         k)
         KEEP_CONFIG=${OPTARG}
         ;;
         :)
         /usr/bin/echo "ERROR -${OPTARG} requires an argument"
         exit_error
         ;;
         *)
         exit_error
         ;;
     esac
done


if [ -z "$REQUESTED_BACKUP" ]; then
    DATA_BACKUP_FILE=$DEFAULT_BACKUP_FILE
else
    DATA_BACKUP_FILE="$REQUESTED_BACKUP"
fi

# Check If File Exists
if [ ! -f "$DATA_BACKUP_FILE" ]; then
    echo "Backup File $DATA_BACKUP_FILE Not Found"  >> $LOGFILE
    exit 1
fi

# Change Permissions
echo "changing permissions - chmod 600"  >> $LOGFILE
/usr/bin/chmod 600 $DATA_BACKUP_FILE $CONFIG_BACKUP_FILE

# Run keep_config check here
# Extract Configuration Backup
if [ $KEEP_CONFIG ]; then
    /usr/bin/echo "Keeping Config" >> $LOGFILE
    /usr/bin/tar -xvf $CONFIG_BACKUP_FILE --exclude='/etc/gitlab/gitlab.rb*' --strip-components=2 -C /etc/gitlab/
else
    /usr/bin/tar -xvf $CONFIG_BACKUP_FILE --strip-components=2 -C /etc/gitlab/
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
    echo "ApplicationSetting.last.update(home_page_url: '${GITLAB_URL}explore')" | /usr/bin/gitlab-rails console >> $LOGFILE && break || sleep 15
done

/usr/bin/systemctl restart ssh-gitlab

/usr/local/sbin/enable-puppet "Running Backup Restore"
