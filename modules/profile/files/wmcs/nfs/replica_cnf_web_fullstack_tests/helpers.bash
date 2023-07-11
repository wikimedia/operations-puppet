#!/usr/bin/env bats
#- SPDX-License-Identifier: Apache-2.0
# You need to export some variables
#   HTTP_USER
#   HTTP_PASSWORD
# You can override some of the configs (for local testing for example):
#   CONF_FILE -> path to the repliac config yaml file
#   PROJECT   -> set to localtest if doing local testing
#   TOOL_NAME -> when doing a localtest, the username to create the conf file for
#   USER_ID   -> when doing a localtest, the numeric uid of the user


CONF_FILE="${CONF_FILE:-/etc/replica_cnf_config.yaml}"
if [[ $BASE_URL == "" ]]; then
    HTTP_USER="${HTTP_USER?}"
    HTTP_PASSWORD="${HTTP_PASSWORD?}"
    BASE_URL="http://${HTTP_USER}:${HTTP_PASSWORD}@127.0.0.1:${PORT:-80}/v1"
fi

if [[ "${PROJECT}" == "" ]]; then
    if [[ -e "/etc/wmcs-project" ]]
    then
        PROJECT="$(cat /etc/wmcs-project)"
    else
        PROJECT="file /etc/wmcs-project does not exist"
    fi
fi

TOOL_BASE_PATH=$(grep -E "^TOOL_REPLICA_CNF_PATH *: *" "$CONF_FILE" | sed -e 's/^.*: *"\?\([^"]*\)"\?/\1/')
PAWS_BASE_PATH=$(grep -E "^PAWS_REPLICA_CNF_PATH *: *" "$CONF_FILE" | sed -e 's/^.*: *"\?\([^"]*\)"\?/\1/')
USER_BASE_PATH=$(grep -E "^USER_REPLICA_CNF_PATH *: *" "$CONF_FILE" | sed -e 's/^.*: *"\?\([^"]*\)"\?/\1/')
PROJECT_PREFIX=$(grep -E "^ *tools_project_prefix *: *" "$CONF_FILE" | sed -e 's/^.*: *"\?\([^"]*\)"\?/\1/')
case $PROJECT in
    testlabs)
        TOOL_NAME="toolsbeta.test"
        SHORT_TOOL_NAME="test"
        USER_ID=51595
        ;;
    toolsbeta)
        TOOL_NAME="toolsbeta.test"
        SHORT_TOOL_NAME="test"
        USER_ID=51595
        ;;
    localtest)
        TOOL_NAME="${TOOL_NAME:?}"
        SHORT_TOOL_NAME="${TOOL_NAME:$((${#PROJECT_PREFIX}+1))}"
        USER_ID="${USER_ID:?}"
        ;;
    *)
        SHORT_TOOL_NAME="test"
        TOOL_NAME="${PROJECT_PREFIX}.${SHORT_TOOL_NAME}"
        USER_ID="52503"
        ;;
esac

make_test_dir () {
    local path="${1?}"
    mkdir -p "$path"
}

delete_test_replica_cnf () {
    local path="${1?}"
    shopt -s dotglob
    shopt -s nullglob
    for each_file in "$path"/*.my.cnf; do
        chattr -i "$each_file"
        rm "$each_file"
    done
    shopt -u dotglob
    shopt -u nullglob
}

do_curl() {
    local path="${1?}"
    local data="${2?}"
    curl \
        --header "x-forwarded-proto: https" \
        --silent \
        "${BASE_URL}/${path}" \
        -H 'Content-Type: application/json' \
        -d "$data"
}


is_equal() {
    local left="${1?}"
    local right="${2?}"
    diff <( printf '%s' "$left" ) <( printf "%s" "$right" ) \
    && return 0
    echo -e "is_equal failed\nleft: $left\nright: $right" >&2
    return 1
}


match_regex() {
    local regex="${1?}"
    local what="${2?}"
    [[ "$what" =~ $regex ]] && return 0
    echo -e "match_regex failed\nregex: '$regex'\nwhat: $what" >&2
    return 1
}


json_has_equal() {
    local key="${1?}"
    local value="${2?}"
    local data="${3?}"

    local cur_value=$(echo "$data" | jq -r ".$key") \
    && is_equal "$cur_value" "$value" \
    && return 0

    echo -e "json_has_equal: key '$key' with value '$value' not found in \n$data" >&2
    return 1 
}


json_has_match() {
    local key="${1?}"
    local match="${2?}"
    local data="${3?}"

    local cur_value=$(echo "$data" | jq -r ".$key")
    match_regex "$match" "$cur_value" && return 0

    echo -e "json_has_match: key '$key' value '$gotten_value' does not match '$match'" >&2
    return 1 
}


exists() {
    local path="${1?}"
    [[ -e "$path" ]] || {
        echo "exists: $path not found"
        return 1
    }
    return 0
}
