#!/bin/bash
# Common bash functions and variables to use for scripts
PUPPETLOCK=$(puppet agent --configprint agent_catalog_run_lockfile)
PUPPET_DISABLEDLOCK=$(puppet agent --configprint agent_disabled_lockfile)

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
