#!/bin/bash
# Common bash functions and variables to use for scripts
PUPPET_CONFIG="$(puppet config print)"

# Function to get a puppet config variable
# Parameters:
#  $1: the name of the variable to get from the config
get_puppet_config() {
    # Using xargs to trim the string
    echo "${PUPPET_CONFIG}" | grep "${1}" | cut -d "=" -f2- | xargs
}

PUPPETLOCK="$(get_puppet_config agent_catalog_run_lockfile)"
PUPPET_DISABLEDLOCK="$(get_puppet_config agent_disabled_lockfile)"
PUPPET_SUMMARY="$(get_puppet_config lastrunfile)"

# Function to test if puppet is running or not
puppet_is_running() {
    # If no lockfile is defined, we can't really tell what's happening.
    # Assume puppet is not running in this case
    test -n "$PUPPETLOCK" || return 1

    # If the lockfile is not present, puppet is not running
    test -e "$PUPPETLOCK" || return 1

    # Now let's see if the PID at $PUPPETLOCK is indeed present and running
    local puppetpid=$(cat "$PUPPETLOCK")
    local cmdline_file="/proc/${puppetpid}/cmdline"
    if [ -f "$cmdline_file" ]; then
        # Puppet is indeed running
        grep -q puppet "$cmdline_file" && return 0
    fi

    # The lock file is stale, ignore it
    echo "Ignoring stale puppet agent lock for pid ${puppetpid}"
    return 1
}

# loop function to wait for puppet to finish its execution
wait_for_puppet() {
    local attempts=${1:-30}
    for _ in $(seq "$attempts"); do
        if ! puppet_is_running; then
            return 0
        fi
        sleep 10
    done
    # If puppet is still running at this point, report an error
    return 1
}

last_run_success() {
    local ruby_script

    ruby_script=$(cat <<'RUBY_SCRIPT'
    require 'safe_yaml'
    SafeYAML::OPTIONS[:default_mode] = :safe
    begin
        a = YAML.load(STDIN.read)
        puts a['resources']['failed'] + a['events']['failure']
    rescue
        # Consider malformed yaml as a failure
        puts 1
    end
RUBY_SCRIPT
    )

    if [[ -e "${PUPPET_SUMMARY}" && "$(ruby -e "${ruby_script}" < "${PUPPET_SUMMARY}")" -eq "0" ]]; then
        return 0
    fi

    return 1
}
