#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# deploy wikistats
# puppet git pulls files into /srv/wikistats/ after a merge
# then this script copies files into the right places

pn="wikistats"
dps=('var/www' 'etc' 'usr/lib' 'usr/share/php' 'usr/local/bin')
pp="/srv"
bp="/usr/lib/wikistats/backup"
dbpass=$(cat /usr/lib/wikistats/wikistats-db-pass)

function deploy {

  echo -e "\nfirst running puppet to git pull\n"
  sudo puppet agent -tv
  # with -t, exit code 2 means "changes applied", which is fine
  rc=$?
  if [ "$rc" -ne 0 ] && [ "$rc" -ne 2 ]; then
    echo "puppet run failed (exit code ${rc}), not deploying"
    exit 1
  fi
  echo -e "\ndeploying files from git repository (${pp}/${pn})\n"

  for dp in "${dps[@]}"; do
    mkdir -p /${dp}/${pn}
    echo "rsync -avp ${pp}/${pn}/${dp}/${pn}/ /${dp}/${pn}/"
    rsync -avp ${pp}/${pn}/${dp}/${pn}/ /${dp}/${pn}/
  done
  # insert db password not included in public repo
  echo -e "\ninsert db password not included in public repo\n"
  echo -e "sed -i \"s/<not included>/(password)/g\" /etc/${pn}/config.php\n"
  # escape characters that have a special meaning in the sed replacement
  dbpass_sed=$(printf '%s' "${dbpass}" | sed -e 's/[\/&]/\\&/g')
  sed -i "s/<not included>/${dbpass_sed}/g" /etc/${pn}/config.php
}

function diff {

  for dp in "${dps[@]}"; do
    mkdir -p /${dp}/${pn}
    echo "/${dp}/${pn}/"
    rsync -avn ${pp}/${pn}/${dp}/${pn}/ /${dp}/${pn}/ --info=stats0,flist0 | grep -v -x -F "./"
    echo -e "\n"
  done
}

function backup {

  mkdir -p ${bp}
  echo -e "\nbacking up files to backup location (${bp})\n"

  for dp in "${dps[@]}" ; do
    mkdir -p ${bp}/${pn}/${dp}/${pn}
    # the backup location is inside /usr/lib/wikistats, don't back it up into itself
    excl=()
    if [ "/${dp}/${pn}/backup" = "${bp}" ]; then
      excl=(--exclude=/backup/)
    fi
    echo "rsync -avp ${excl[*]} /${dp}/${pn}/ ${bp}/${pn}/${dp}/${pn}/"
    rsync -avp "${excl[@]}" /${dp}/${pn}/ ${bp}/${pn}/${dp}/${pn}/
  done

}

function restore {

  echo -e "\nrestoring files, deploy from backup location (${bp})\n"

  for dp in "${dps[@]}" ; do
    mkdir -p /${dp}/${pn}
    echo "rsync -avp ${bp}/${pn}/${dp}/${pn}/ /${dp}/${pn}/"
    rsync -avp ${bp}/${pn}/${dp}/${pn}/ /${dp}/${pn}/
  done

}

function help {

  echo -e "usage: $0 <action>. action can be one of 'deploy', 'diff', 'backup' or 'restore'\n"
  echo -e "deploy: syncs files from ${pp}/${pn} (where puppet git pulls to automatically) into the right places.\n"
  echo -e "diff: identifies files that have local hacks that have not been deployed.\n"
  echo -e "backup: syncs files currently used to a backup location at ${bp}.\n"
  echo -e "restore: syncs files from the backup location (${bp}) into the right places.\n"
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
