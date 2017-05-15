#!/bin/bash
# deploy wikistats
# puppet git pulls files into /srv/wikistats/ after a merge
# then this script copies files into the right places

pn="wikistats"
dps=('var/www' 'etc' 'usr/lib' 'usr/share/php' 'usr/local/bin')
pp="/srv"
bp="/root/wsbackup"
dbpass=$(cat /root/wikistats-db-pass)

function deploy {

  echo -e "\nfirst running puppet to git pull\n"
  sudo puppet agent -tv
  echo -e "\ndeploying files from git repository (${pp}/${pn})\n"

  for dp in "${dps[@]}"; do
    mkdir -p /${dp}/${pn}
    echo "rsync -avp ${pp}/${pn}/${dp}/${pn}/ /${dp}/${pn}/"
    rsync -avp ${pp}/${pn}/${dp}/${pn}/ /${dp}/${pn}/
  done
  # insert db password not included in public repo
  echo -e "\ninsert db password not included in public repo\n"
  echo -e "sed -i \"s/<not included>/${dbpass}/g\" /etc/${pn}/config.php\n"
  sed -i "s/<not included>/${dbpass}/g" /etc/${pn}/config.php
}

function backup {

  mkdir -p /root/wsbackup
  echo -e "\nbacking up files to to backup location {${bp})\n"

  for dp in "${dps[@]}" ; do
    mkdir -p ${bp}/${pn}/${dp}/${pn}
    echo "rsync -avp /${dp}/${pn}/ ${bp}/${pn}/${dp}/${pn}/"
    rsync -avp /${dp}/${pn}/ ${bp}/${pn}/${dp}/${pn}/
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

  echo -e "usage: $0 <action>. action can be one of "deploy", "backup" or "restore"\n"
  echo -e "deploy: syncs file from ${pp}/${pn} (where puppet git pulls to automatically) into the right places.\n"
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


