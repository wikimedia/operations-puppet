#!/usr/bin/env bash

# cp /etc/gitlab/gitlab.rb /etc/gitlab/gitlab.rb.bak
# cp /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.bak
echo "Running Pre-requisites..."

# Create Backup Configuration Files
CONFIG_FILE=/etc/gitlab/gitlab.rb
SECRETS_FILE=/etc/gitlab/gitlab-secrets.json

if [ -f "$CONFIG_FILE" ] && [ -f "$SECRETS_FILE" ]; then
    echo "Creating backup of $CONFIG_FILE and $SECRETS_FILE"
    cp $CONFIG_FILE $CONFIG_FILE.bak
    cp $SECRETS_FILE $SECRETS_FILE.bak
else
    echo "Configuration File: $CONFIG_FILE Not Found"
    exit 1
fi

# cp /srv/gitlab-backup/latest/latest.tar /srv/gitlab-backup/latest_gitlab_backup.tar

OLD_BACKUP_FILE=/srv/gitlab-backup/latest/latest.tar
NEW_BACKUP_FILE=/srv/gitlab-backup/latest_gitlab_backup.tar
if [ -f "$OLD_BACKUP_FILE" ]; then
    echo "Moving $OLD_BACKUP_FILE to $NEW_BACKUP_FILE"
    cp $OLD_BACKUP_FILE $NEW_BACKUP_FILE
else
    echo "Backup File $OLD_BACKUP_FILE Not Found"
    exit 1
fi


CONFIG_BACKUP=/etc/gitlab/config_backup/latest/latest.tar

# Change Permissions
chmod 600 $NEW_BACKUP_FILE $CONFIG_BACKUP
# chown git.git $NEW_BACKUP_FILE $CONFIG_BACKUP


# normal replica restore
# chown git.git /srv/gitlab-backup/latest_gitlab_backup.tar
# chown git.git /etc/gitlab/config_backup/latest/latest.tar

# Diskspace Check
# df -h

# Package Installation Check
# dpkg -l | grep gitlab

# Extract Configuration Backup
tar -xvf $CONFIG_BACKUP --strip-components=2 -C /etc/gitlab/
if [ -f $CONFIG_FILE.bak ] && [ -f "$SECRETS_FILE" ]; then
    echo "Reverting configuration files to those of the replica..."
    cp $CONFIG_FILE.bak $CONFIG_FILE
    cp $SECRETS_FILE.bak $SECRETS_FILE
else
    echo "Configuration backup files $CONFIG_FILE.bak $SECRETS_FILE.bak not found"
    exit
fi

# Disable Prompts
# GITLAB_ASSUME_YES=1

/usr/bin/gitlab-ctl reconfigure
/usr/bin/gitlab-ctl status

/usr/bin/systemctl stop ssh-gitlab
if [[ $? -ne 0 ]]; then
    echo "something went wrong stopping ssh-gitlab"
    exit 1
fi

# just a sanity check to see if the service is not running
SSH_GITLAB_STATUS=$(/usr/bin/systemctl show -p SubState --value ssh-gitlab)
if [ "${SSH_GITLAB_STATUS}" = "running" ]; then
    echo "ssh-gitlab service still running. please kill it before proceeding"
    exit 1
fi


if /usr/bin/gitlab-ctl stop puma && /usr/bin/gitlab-ctl stop sidekiq; then
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

BACKUP=latest
/usr/bin/gitlab-backup restore GITLAB_ASSUME_YES=1 BACKUP=$BACKUP &> /dev/null
if [ $? == 0 ]; then
   echo "Successfully Restored Backup: $BACKUP"
else
   echo "Something Went Wrong Restoring Backup: $BACKUP"
   exit 1
fi

/usr/bin/gitlab-ctl reconfigure
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

echo "ApplicationSetting.last.update(home_page_url: 'https://gitlab-replica.wikimedia.org/explore')" | /usr/bin/gitlab-rails console

/usr/bin/systemctl restart ssh-gitlab