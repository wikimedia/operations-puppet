#!/bin/bash

# This is a user garbage collection script that removes
# users who do not have a supplementary group that also have
# a UID above the ID_BOUNDARY. Removals are logged to syslog.
# with 'dryrun' as first arg exits 1 if cleanup is needed

PASSWD='/etc/passwd'
ID_BOUNDRY='500'

function log() {
    logger $1
    echo $1
}

IFS=$'\r\n' PASSWD_USERS=($(cat $PASSWD))
for var in "${PASSWD_USERS[@]}"
do
  username=`grep ${var} /etc/passwd | cut -d ':' -f 1`
  uid=`grep ${var} /etc/passwd | cut -d ':' -f 3`
  if [[ "$uid" -gt "$ID_BOUNDRY" ]]; then
    if [[ `id $username` != *","* ]]; then
      if [ "${1}" == "dryrun" ]
        then
          exit 1
      fi
      log "${0} removing user:""${var}"
      /usr/sbin/deluser --remove-home --backup-to=/tmp $username &> /dev/null
    fi
  fi
done
