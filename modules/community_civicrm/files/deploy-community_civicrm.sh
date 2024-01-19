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

  echo -e "First running puppet to git pull\n"
  sudo puppet agent -tv
  echo -e "Deploying files from git repository (${pp}/${pn})\n"

  for dp in "${dps[@]}"; do
    mkdir -p "/var/www/${pn}/${dp}"
    echo "rsync -avp --cvs-exclude --delete-excluded ${pp}/${pn}/${dp}/ /var/www/${pn}/${dp}/"
    rsync -avp "${pp}/${pn}/${dp}/" "/var/www/${pn}/${dp}/"
  done

  echo -e "Final puppet run to fix any possible permission/template issues\n"
  sudo puppet agent -tv
}

function diff {

  echo -e "Rsync test for new/updated files:\n"

  for dp in "${dps[@]}"; do
    mkdir -p "/var/www/${pn}/${dp}"
    echo "Checking /var/www/${pn}/${dp}"
    echo "rsync -avn --cvs-exclude \"${pp}/${pn}/${dp}/\" \"/var/www/${pn}/${dp}/\" --info=stats0,flist0 | grep -v \"\\./\""
    rsync -avn --cvs-exclude "${pp}/${pn}/${dp}/" "/var/www/${pn}/${dp}/" --info=stats0,flist0 | grep -v "\./"
    echo -en "\n"
  done
}

function backup {

  mkdir -p ${bp}
  echo -e "Backing up files to backup location {${bp})\n"

  for dp in "${dps[@]}" ; do
    echo "Backing up ${pn}/${dp}"
    mkdir -p "${bp}/${pn}/${pn}/${dp}"
    echo "rsync -avp /var/www/${pn}/${dp}/ ${bp}/${pn}/${pn}/${dp}/"
    rsync -avp "/var/www/${pn}/${dp}/" "${bp}/${pn}/${pn}/${dp}/"
    echo -en "\n"
  done

}

function restore {

  echo -e "Restoring files, deploy from backup location (${bp})\n"

  for dp in "${dps[@]}" ; do
    echo "Restoring ${pn}/${dp}"
    mkdir -p "/var/www/${pn}/${dp}"
    echo "rsync -avp ${bp}/${pn}/${pn}/${dp}/ /var/www/${pn}/${dp}/"
    rsync -avp "${bp}/${pn}/${pn}/${dp}/" "/var/www/${pn}/${dp}/"
    echo -en "\n"
  done

}

function help {

  echo -e "Usage: $0 <action>\n"
  echo -e "Actions:"
  echo -e "  deploy: syncs file from ${pp}/${pn} (where puppet git pulls to automatically) into the right places."
  echo -e "  diff: identifies files that have local hacks or that have not been deployed."
  echo -e "  backup: syncs files currently used to a backup location at ${bp}."
  echo -e "  restore: syncs file from the backup location {$bp} into the right places."
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


