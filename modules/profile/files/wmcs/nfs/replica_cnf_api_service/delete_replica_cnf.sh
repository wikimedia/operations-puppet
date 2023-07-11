#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

set -e

die(){
    echo >&2 "$@"
    exit 1
}

# validate number of args passed
[[ "$#" -eq 2 ]] || die "2 arguments required, $# provided"

path=$1
account_type=$2

# verify that account type is either tool, paws and user
[[ $account_type =~ ^(tool|paws|user)$ ]] || die "account_type is expected to be one of 'tool', 'paws', 'user'. Got $account_type"

# allow overriding the conf file path when in testing (no /etc/wmcs-project file)
FINAL_CONF_FILE="/etc/replica_cnf_config.yaml"
if [[ ! -e /etc/wmcs-project ]]; then
    FINAL_CONF_FILE="${CONF_FILE:-$FINAL_CONF_FILE}"
fi

get_base_path(){

    local account_type="${1?no account_type passed}"
    local base_path conf_entry

    case $account_type in
        'tool')
            conf_entry='TOOL_REPLICA_CNF_PATH'
            ;;
        'paws')
            conf_entry='PAWS_REPLICA_CNF_PATH'
            ;;
        'user')
            conf_entry='USER_REPLICA_CNF_PATH'
            ;;
    esac

    base_path=$(\
        grep -P "^$conf_entry *: *\"?.*\"?" "$FINAL_CONF_FILE" \
        | sed -e 's/^.*: *"\?\([^"]*\)"\?/\1/'
    )
    # verify that base_path exists
    [[ -d "${base_path}" ]] || die "${base_path}: No such file or directory"
    echo "${base_path}"
}

base_path=$(get_base_path "${account_type}")
full_path="${base_path}/${path}"

# verify that the provided path is a file
[[ -f "$full_path" ]] || die "$full_path: No such file or directory"

# if file is immutable
[[ "$(lsattr "${full_path}")" =~ ----i* ]] && chattr -i "$full_path"

rm -f "$full_path"
# echo full_path to stdout for python script to read.
echo "$full_path"
