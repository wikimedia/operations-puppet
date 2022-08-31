#!/bin/bash

. /etc/phabricator/script-vars

git=$(which git)
logger=$(which logger)
puppet=$(which puppet)
systemctl=$(which systemctl)

function log() {
  echo -e "\n${green}   ->${1}${CLEAR}"
  $logger "${1}"
}

function error() {
  echo ""
  $logger --stderr "${1}"
}

log "Running puppet..."
$puppet agent --test

log "Applying storage migrations"
"$PHAB_DIR"/phabricator/bin/storage upgrade --force -u "$PHAB_STORAGE_USER" -p "$PHAB_STORAGE_PASS"

log "Restarting PHD"
$systemctl start phd

log "Reloading apache"
$systemctl reload apache2

log "Enabling puppet agent"
enable-puppet 'phabricator deployment'

log "Verifying database status"
"$PHAB_DIR"/phabricator/bin/storage status &>/dev/null
retcode=$?
if [ "$retcode" != "0" ]; then
    error ">>>ERROR: Phabricator storage is in a bad state."
    exit 1
fi
