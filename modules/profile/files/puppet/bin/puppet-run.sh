#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

# Bail out early if any of these first commands exit abnormally
set -e

if [ -e /run/puppet/disabled ]; then
  printf "not running: systemd time disabled vi /run/puppet/disabled\n" | logger -t puppet-agent-cronjob
  exit
fi


# Check this before apt-get update, so that our update doesn't screw up
# package installs in a running (manual and/or initial install) puppet run
PUPPETLOCK=$(puppet agent --configprint agent_catalog_run_lockfile)

# From here out, make a best effort to continue in the face of failure
set +e

# Splay sleep at the top, so that the remaining lock checks and acquisitions,
# while not perfect, at least execute reasonably quickly.  The intent of this
# splay is only to dither the cron execution time anyways, and having it dither
# before the apt run is probably more helpful than just the agent run at the
# bottom.  Also, puppet's built-in splay sleep only checks for agent-disable
# before the sleep (but not after), and does not create the agent lockfile
# until after the sleep, which creates a wide race window against tools trying
# to avoid puppet agent concurrency with the "disable and then poll lockfile".
SLEEPVAL=$((RANDOM % 60))
printf "Sleeping %d for random splay\n"  $SLEEPVAL | logger -t puppet-agent-cronjob
sleep $SLEEPVAL

if [ -n "$PUPPETLOCK" ] && [ -e "$PUPPETLOCK" ]; then
    PUPPETPID=$(<"$PUPPETLOCK")
    CMDLINE_FILE="/proc/$PUPPETPID/cmdline"
    if [ -f "$CMDLINE_FILE" ]; then
        if grep -q puppet "$CMDLINE_FILE"; then
            printf "Skipping this run, puppet agent already running at pid %s\n" "$(<"$PUPPETLOCK")"  | logger -t puppet-agent-cronjob
            exit 0
        fi
    fi
    printf "Ignoring stale puppet agent lock for pid %s\n" "$(<"$PUPPETLOCK")"  | logger -t puppet-agent-cronjob
fi

timeout -k 60 300 apt-get update -qq |& logger -t puppet-agent-cronjob

# puppet run logged via syslog
timeout -k 60 1800 puppet agent \
  --onetime \
  --no-daemonize \
  --verbose \
  --show_diff \
  --no-splay \
  > /dev/null 2>&1
