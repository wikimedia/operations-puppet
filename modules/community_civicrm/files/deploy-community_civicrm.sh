#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# deploy community_civicrm
# puppet git pulls files into /srv/community_civicrm/ after a merge
# then this script copies files into the right places

pn="community_civicrm"
dps=('vendor' 'web')
pp="/srv"
bp="/root/backup"

function deploy {

  echo -e "\nfirst running puppet to git pull\n"
  sudo puppet agent -tv
  echo -e "\ndeploying files from git repository (${pp}/${pn})\n"

  for dp in "${dps[@]}"; do
    mkdir -p "/var/www/${pn}/${dp}"
    echo "rsync -avp --cvs-exclude --delete-excluded ${pp}/${pn}/${dp}/ /var/www/${pn}/${dp}/"
    rsync -avp "${pp}/${pn}/${dp}/" "/var/www/${pn}/${dp}/"
  done
}

function diff {

  for dp in "${dps[@]}"; do
    mkdir -p "/var/www/${pn}/${dp}"
    echo "/var/www/${pn}/${dp}/"
    rsync -avn --cvs-exclude "${pp}/${pn}/${dp}/" "/var/www/${pn}/${dp}/" --info=stats0,flist0 | grep -v "./"
    echo "diff -r ${pp}/${pn}/${dp}/ /var/www/${pn}/${dp}/"
    echo -e "\n"
  done
}

function backup {

  mkdir -p ${bp}
  echo -e "\nbacking up files to to backup location {${bp})\n"

  for dp in "${dps[@]}" ; do
    mkdir -p "${bp}/${pn}/${pn}/${dp}"
    echo "rsync -avp /var/www/${pn}/${dp}/ ${bp}/${pn}/${pn}/${dp}/"
    rsync -avp "/var/www/${pn}/${dp}/" "${bp}/${pn}/${pn}/${dp}/"
  done

}

function restore {

  echo -e "\nrestoring files, deploy from backup location (${bp})\n"

  for dp in "${dps[@]}" ; do
    mkdir -p "/var/www/${pn}/${dp}"
    echo "rsync -avp ${bp}/${pn}/${pn}/${dp}/ /var/www/${pn}/${dp}/"
    rsync -avp "${bp}/${pn}/${pn}/${dp}/" "/var/www/${pn}/${dp}/"
  done

}

function help {

  echo -e "usage: $0 <action>. action can be one of 'deploy', 'backup' or 'restore'\n"
  echo -e "deploy: syncs file from ${pp}/${pn} (where puppet git pulls to automatically) into the right places.\n"
  echo -e "diff: identifies files that have local hacks that have not been deployed.\n"
  echo -e "backup: syncs files currently used to a backup location at ${bp}.\n"
  echo -e "restore: syncs file from the backup location {$bp} into the right places.\n"
}

case $1 in
 "backup")
  backup
 ;;
 "deploy")
  deploy
 ;;
 "diff")
  diff
 ;;
 "restore")
  restore
 ;;
 '')
  help
 ;;
 *)
  help
  exit 1
esac


