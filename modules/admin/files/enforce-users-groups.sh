#!/bin/bash

set -e

# This is a user garbage collection script that removes users who do not have a
# supplementary group that also have a UID above the LAST_SYSTEM_UID. Removals
# are logged to syslog. With 'dryrun' as the first argument, it exits 1 if
# cleanup is needed.

# for $LAST_SYSTEM_UID
#. /etc/adduser.conf
# We're in the process of managing adduser config to Puppet and to lower
# the upper boundary for system users to 499 in that config. We do however
# have a number of users which have been created in the 500-999 range, so
# set the upper boundary for the enforce-users-groups script to the old
# value. If/when we migrate legacy users to the new upper limit we can
# read the value from adduser.conf again
LAST_SYSTEM_UID=999

# UIDs >= 50000 are currently either Toolforge tools (< 60000, should never be used in production)
# or system users as assigned by Debian (https://www.debian.org/doc/debian-policy/ch-opersys.html#uid-and-gid-classes)
LAST_USER_UID=49999

ARCHIVE_DIR='/var/userarchive'
EXCLUDE=("nobody" \
         "mwdeploy" \   # eventlog*
         "releases" \   # deployment.eqiad.wmnet
         "reprepro");   # apt1002/2002

log() {
    logger $1
    echo $1
}

in_array() {
    local haystack=${1}[@]
    local needle=${2}
    for i in ${!haystack}; do
        if [[ ${i} == ${needle} ]]; then
            return 0
        fi
    done
    return 1
}

if [ ! -d $ARCHIVE_DIR ]
    then
        log "creating new user files archive ${ARCHIVE_DIR}"
        mkdir -p $ARCHIVE_DIR
fi

IFS=$'\r\n' PASSWD_USERS=($(/usr/bin/getent passwd))
for var in "${PASSWD_USERS[@]}"
do
    username=`echo $var | cut -d ':' -f 1`
    uid=`echo $var | cut -d ':' -f 3`
    # skip dynamic User
    if [ "$(awk -F: '{print $5}' <<<${var})" == "Dynamic User" ]
    then
      continue
    fi

    # A few global accounts of dubious nature are ignored
    if in_array EXCLUDE $username; then
        continue
    fi

    if [[ "$uid" -gt "$LAST_SYSTEM_UID" && "$uid" -lt "$LAST_USER_UID" ]]; then
        if [[ `/usr/bin/id $username` != *","* ]]; then
            if [ "${1}" == "dryrun" ]; then
                exit 1
            fi

            log "${0} removing user/id: ${username}/${uid}"
            if [ -f /etc/sudoers.d/$username ]; then
                mv /etc/sudoers.d/$username /home/$username
            fi
            /usr/sbin/deluser --remove-home --backup-to=$ARCHIVE_DIR $username &> /dev/null
        fi
    fi
done
