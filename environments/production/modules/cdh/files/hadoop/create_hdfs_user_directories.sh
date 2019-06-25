#!/bin/bash

set -e

usage_message="Usage $(basename "$0") [--dry-run|-n] [-v|--verbose] <group> [<groupB> <groupC> ...]"


help_message="${usage_message}

Manages HDFS user directories.

This will ensure that users in the specified list of groups
all have HDFS user (home) directories at hdfs:///user/<username>.
This script must be run by the HDFS super user 'hdfs'.

Options:
  -c, --check-for-changes  Checks if there are any HDFS user directories
                           that need created for users in <group>.
                           If there are, this will exit 3.
  -n, --dry-run            Don't actually create directories, just
                           output what would have been done.  Note that
                           this option does nothing when combined with -c.
  -v, --verbose            Run in verbose mode.
"

dry_run='false'
verbose='false'
check_for_changes='false'


if [ $(whoami) != 'hdfs' ]; then
    echo "Error: $(basename "$0") must be run as the 'hdfs' user." >&2
    exit 1
fi


function log_message {
    local message="${1}"
    if [ "${verbose}" == 'true' ]; then
        echo "$(date "+%Y-%m-%dT%H:%M:%S") ${message}"
    fi
}


function create_hdfs_user_directory {
    local user="${1}"

    mkdir_command="hdfs dfs -mkdir /user/${user}"
    chown_command="hdfs dfs -chown ${user}:${user} /user/${user}"

    log_message "${mkdir_command} && ${chown_command}"

    if [ "${dry_run}" == 'false' ]; then
        $mkdir_command && $chown_command
    fi
}



# Parse CLI args
while [ $# -ne 0 ]; do

    case "$1" in
        -n|--dry-run)
            dry_run='true'
            ;;
        -c|--check-for-changes)
            check_for_changes='true'
            ;;
        -v|--verbose)
            verbose='true'
            ;;
        -h|--help)
            echo "${help_message}"
            exit 0
            ;;
        *)
            break
            ;;
    esac
    shift
done


if [ $# -eq 0 ]; then
    echo "Error: Must specify at least one group." >&2
    exit 1
fi


# Assume the remaining arguments are all group names
# and get a uniq list of members in each group.
groups="$@"
group_members=$(/usr/bin/getent group ${groups} | /usr/bin/awk -F ':' '{print $NF}' | tr ',' '\n' | sort | uniq)


# Get a list of existant HDFS user directories.
hdfs_user_directories=$(/usr/bin/hdfs dfs -ls /user | /usr/bin/awk '{print $NF}' | /bin/sed 's@/user/@@g')


if [ "${dry_run}" == 'true' -a "${check_for_changes}" == 'false' ]; then
    log_message "--dry-run mode on; not actually doing anything."
fi

# For each user in $groups, make sure that
# user has an HDFS user directory.  If they don't,
# go ahead and create it now
for user in $group_members; do

    # Turn off set +e so a mis-matched grep doesn't abort the script.
    set +e
    # Look for the user's directory in the list of existant directories.
    echo "${hdfs_user_directories}" | grep -q "${user}$"
    directory_exists=$?
    set -e

    # If the above grep returned 1, the user
    # directory needs to be created.
    if [ $directory_exists -ne 0 ]; then
        # If we are just checking for changes AND we found a user
        # that needs a home directory created, then we can exit
        # now.
        if [ "${check_for_changes}" == 'true' ]; then
            log_message "There are HDFS user directories that need created for users in groups '${groups}', exiting 3."
            exit 3
        # Otherwise go ahead and create the user directory.
        else
            create_hdfs_user_directory "${user}"
        fi
    fi
done
