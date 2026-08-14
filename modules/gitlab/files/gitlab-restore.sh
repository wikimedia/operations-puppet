#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

. /srv/gitlab-backup/gitlab-backup-restore-common.sh

DEFAULT_BACKUP_FILE=$(ls -t /srv/gitlab-backup/*gitlab_backup.tar | head -n1)
CONFIG_BACKUP_FILE=$(ls -t /srv/gitlab-backup/gitlab_config*.tar | head -n1)
REQUESTED_BACKUP=""
GITLAB_URL=$(grep '^external_url ' /etc/gitlab/gitlab.rb | cut -d '"' -f2)
# prevent restore on production by default
FORCE_RESTORE=false

usage() {
  /usr/bin/echo "Usage: $0 [ -f REQUESTED_BACKUP -F <force restore on non-replicas> ]" 1>&2
}

exit_error() {
    usage
    exit 1
}

# Publish the version-mismatch state consumed by the GitLabRestoreVersionMismatch
# alert: 1 while the version gate blocks the restore (with both versions as
# labels), 0 once the gate passes again. POST only replaces this metric name in
# the pushgateway group, the restore success metrics are untouched.
push_version_mismatch() {
    value=$1
    labels=$2
    echo "gitlab_restore_version_mismatch{instance=\"${HOSTNAME}:0\", type=\"restore\"${labels}} ${value}" \
        | curl --data-binary @- "http://${PROMETHEUS_PUSHGATEWAY_HOST}/metrics/job/gitlab_restore/host/${HOSTNAME}" || true
}

lock_backups

while getopts ":fF" options; do
    case "${options}" in
         f)
         REQUESTED_BACKUP=${OPTARG}
         ;;
         F)
         FORCE_RESTORE=true
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

restore_start_time=$(date +%s)

# Check if host is production
if [[ $GITLAB_URL != *"replica"* ]] && [[ $GITLAB_URL != *"wmcloud"* ]]; then
  # production needs additional force flag -F
  if [ $FORCE_RESTORE == true ] ; then
    /usr/bin/echo "Force flag -F provided, restoring production instance"
  else
    /usr/bin/echo "Please use force flag -F to restore production instance"
    exit 1
  fi
fi

# Chose data backup file
if [ -z "$REQUESTED_BACKUP" ]; then
    /usr/bin/echo "No REQUESTED_BACKUP provided, using latest backup $DEFAULT_BACKUP_FILE"
    DATA_BACKUP_FILE=$DEFAULT_BACKUP_FILE
else
    /usr/bin/echo "REQUESTED_BACKUP provided, using $REQUESTED_BACKUP"
    DATA_BACKUP_FILE="$REQUESTED_BACKUP"
fi

# check if installed GitLab version matches backup version
installed_version=$(dpkg -l gitlab-ce | grep -Po "\\d*\.\\d*\.\\d*")
backup_version=$(tar -axf $DATA_BACKUP_FILE backup_information.yml -O | grep gitlab_version  | grep -Po "\\d*\.\\d*\.\\d*")

if [ $installed_version != $backup_version ]; then
    /usr/bin/echo "Installed GitLab version $installed_version doesn't match backup GitLab version $backup_version"
    push_version_mismatch 1 ", installed_version=\"${installed_version}\", backup_version=\"${backup_version}\""
    exit 1
fi
push_version_mismatch 0 ""

echo "Running Pre-requisites..."

# Check if backup files exist
if [ ! -f "$CONFIG_BACKUP_FILE" ]; then
    /usr/bin/echo "Configuration File: $CONFIG_BACKUP_FILE Not Found"
    exit 1
fi

if [ ! -f "$DATA_BACKUP_FILE" ]; then
    echo "Backup File $DATA_BACKUP_FILE Not Found"
    exit 1
fi

# Change Permissions
echo "changing access permissions of backups"
/usr/bin/chmod 600 $DATA_BACKUP_FILE $CONFIG_BACKUP_FILE
/usr/bin/chown git.git $DATA_BACKUP_FILE $CONFIG_BACKUP_FILE

# disable puppet to prevent stopped services from restart
# during the backup restoration process
/usr/local/sbin/disable-puppet "Running Backup Restore"

# Extract Configuration Backup
/usr/bin/echo "Restore config backup"
/usr/bin/tar -xvf $CONFIG_BACKUP_FILE --exclude='/etc/gitlab/gitlab.rb*' --strip-components=2 -C /etc/gitlab/

echo "running gitlab-ctl reconfigure"
/usr/bin/gitlab-ctl reconfigure
/usr/bin/gitlab-ctl status


if /usr/bin/systemctl is-active --quiet ssh-gitlab.service; then
    echo "stopping ssh-gitlab.service"
    /usr/bin/systemctl stop ssh-gitlab.service
    if [[ $? -ne 0 ]]; then
        echo "Failed to stopping ssh-gitlab.service"
        exit 1
    fi
else
    echo "ssh-gitlab.service already stopped."
fi

if /usr/bin/gitlab-ctl graceful-kill puma && /usr/bin/gitlab-ctl stop sidekiq; then
    echo "stopped puma & sidekiq service"
else
    echo "something went wrong stopping /usr/bin/gitlab-ctl services"
fi


/usr/bin/gitlab-ctl status | grep "down: puma" &> /dev/null
if [ $? == 0 ]; then
   echo "puma service stopped"
else
    echo "puma service still running"
    exit 1
fi

/usr/bin/gitlab-ctl status | grep "down: sidekiq" &> /dev/null
if [ $? == 0 ]; then
   echo "sidekiq service stopped"
else
    echo "sidekiq service still running"
    exit 1
fi

echo "running gitlab-backup restore"
BACKUP=$(basename $DATA_BACKUP_FILE | sed 's/_gitlab_backup.tar//') #GitLab referes to the timestamp, not full file names
/usr/bin/gitlab-backup restore GITLAB_ASSUME_YES=1 BACKUP=$BACKUP
if [ $? == 0 ]; then
   echo "Successfully Restored Backup: $BACKUP"
else
   echo "Something Went Wrong Restoring Backup: $BACKUP"
   exit 1
fi

echo "running gitlab-ctl reconfigure"
/usr/bin/gitlab-ctl reconfigure

echo "running gitlab-ctl restart"
/usr/bin/gitlab-ctl restart

/usr/bin/gitlab-ctl status | grep "run: puma" &> /dev/null
if [ $? == 0 ]; then
   echo "puma service running"
else
    echo "puma service not running"
    exit 1
fi

/usr/bin/gitlab-ctl status | grep "run: sidekiq" &> /dev/null
if [ $? == 0 ]; then
   echo "sidekiq service running"
else
    echo "sidekiq service not running"
    exit 1
fi

/usr/bin/gitlab-rake gitlab:check SANITIZE=true
/usr/bin/gitlab-rake gitlab:doctor:secrets

for i in {1..10}; do
    echo "ApplicationSetting.last.update(home_page_url: '${GITLAB_URL}explore')" | /usr/bin/gitlab-rails console && break || sleep 15
done

# Check if host is a replica
if [[ $GITLAB_URL == *"replica"* ]] ; then
  # replica hosts use a additional banner
  gitlab-rails runner 'System::BroadcastMessage.create(message: "🚨**THIS IS A REPLICA**🚨
  -- You probably want to use the production gitlab, https://gitlab.wikimedia.org.
  Data on this instance is likely to be overwritten at short notice.
  Login with hardware 2FA key does not work, please use one-time passwords.",
  theme: System::BroadcastMessage.themes["light-red"], dismissable: false, starts_at: 10.minutes.ago, ends_at: 10.years.from_now)'
fi

/usr/bin/systemctl restart ssh-gitlab

/usr/local/sbin/enable-puppet "Running Backup Restore"

restore_end_time=$(date +%s)
restore_duration=$(( ${restore_end_time} - ${restore_start_time} ))
# The backup mtime is its creation time on the primary (rsync -avp preserves it),
# so this metric exposes the end-to-end staleness of the backup+rsync+restore chain.
send_prometheus_metrics restore restore $restore_duration "$(stat -c %Y "$DATA_BACKUP_FILE")"