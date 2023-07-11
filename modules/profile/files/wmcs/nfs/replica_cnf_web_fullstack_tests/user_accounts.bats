#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
load helpers

setup() {
    make_test_dir "${USER_BASE_PATH}/${TOOL_NAME}"
}

@test "user: dry_run read replica cnf" {
    data='{
            "account_id": "'$TOOL_NAME'",
            "account_type": "user",
            "mysql_user": "dummy_mysql_user",
            "dry_run": true
    }'

    run do_curl read-replica-cnf "$data"

    [[ "$status" == "0" ]]
    json_has_equal "result" "ok" "$output"
    json_has_match "detail.password" "..*" "$output"
    json_has_equal "detail.user" "dry.run.username" "$output"
}


@test "user: dry_run write replica cnf" {
    data='{
            "account_id": "'$TOOL_NAME'",
            "account_type": "user",
            "uid": "'$USER_ID'",
            "mysql_username": "dummy_mysql_user",
            "password": "dummypass",
            "dry_run": true
    }'

    run do_curl write-replica-cnf "$data"

    is_equal "$status" "0"
    json_has_equal "result" "ok" "$output"
    json_has_equal "detail.replica_path" "${USER_BASE_PATH}/${TOOL_NAME}/replica.my.cnf" "$output"
}


@test "user: dry_run delete replica cnf" {
    data='{
            "account_id": "'$TOOL_NAME'",
            "account_type": "user",
            "dry_run": true
    }'

    run do_curl delete-replica-cnf "$data"

    is_equal "$status" "0"
    json_has_equal "result" "ok" "$output"
    json_has_match "detail.replica_path" ".*${USER_BASE_PATH}/${TOOL_NAME}/replica.my.cnf.*" "$output"
}



@test "user: write replica cnf works if it's new" {
    data='{
            "account_id": "'$TOOL_NAME'",
            "account_type": "user",
            "uid": "'$USER_ID'",
            "mysql_username": "dummy_mysql_user",
            "password": "dummypass",
            "dry_run": false
    }'
    cnf_path="${USER_BASE_PATH}/${TOOL_NAME}/replica.my.cnf" 
    [[ -e  "$cnf_path" ]] \
    && {
        sudo chattr -i "$cnf_path"
        sudo rm -f "$cnf_path"
    } || :
    expected_contents='[client]
user = dummy_mysql_user
password = dummypass'

    run do_curl write-replica-cnf "$data"

    is_equal "$status" "0"
    json_has_equal "result" "ok" "$output"
    json_has_equal "detail.replica_path" "$cnf_path" "$output"
    exists "$cnf_path"
    is_equal "$(sudo cat "$cnf_path")" "$expected_contents"

    run sudo ls -lan "$cnf_path"
    match_regex "^-r--r-----.* 1 ${USER_ID} ${USER_ID} .*" "$output"

    # in CI we don't have root, so we can't chattr files, we can't really test for this
    if [[ $UID == "0" ]]; then
        run sudo lsattr "$cnf_path"
        match_regex "^----i---.*" "$output"
    fi
}


@test "user: write replica cnf does not overwrite if it exists already" {
    data='{
            "account_id": "'$TOOL_NAME'",
            "account_type": "user",
            "uid": "'$USER_ID'",
            "mysql_username": "new_dummyuser",
            "password": "new_dummypass",
            "dry_run": false
    }'
    cnf_path="${USER_BASE_PATH}/${TOOL_NAME}/replica.my.cnf" 
    exists "$cnf_path"

    run do_curl write-replica-cnf "$data"

    is_equal "$status" "0"
    json_has_equal "result" "skip" "$output"
}


@test "user: read replica cnf matches the one we created" {
    data='{
            "account_id": "'$TOOL_NAME'",
            "account_type": "user",
            "mysql_user": "dummy_mysql_user",
            "dry_run": false
    }'
    cnf_path="${USER_BASE_PATH}/${TOOL_NAME}/replica.my.cnf" 

    run do_curl read-replica-cnf "$data"

    is_equal "$status" "0"
    json_has_equal "result" "ok" "$output"
    json_has_match "detail.password" ".*" "$output"
    json_has_equal "detail.user" "dummy_mysql_user" "$output"
}

@test "user: delete replica cnf deletes it from the filesystem" {
    data='{
            "account_id": "'$TOOL_NAME'",
            "account_type": "user",
            "dry_run": false
    }'
    cnf_path="${USER_BASE_PATH}/${TOOL_NAME}/replica.my.cnf" 

    run do_curl delete-replica-cnf "$data"

    is_equal "$status" "0"
    json_has_equal "result" "ok" "$output"
    json_has_match "detail.replica_path" ".*$cnf_path.*" "$output"

    ! exists "$cnf_path"
}

# TODO: replace test with teardown_file once we have bats >0.4
# IT IMPORTANT THAT THIS TEST BE THE LAST TEST IN THIS FILE!
@test "custom teardown_file function" {
  delete_test_replica_cnf "${USER_BASE_PATH}/${TOOL_NAME}"
  skip
} 
