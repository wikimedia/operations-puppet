#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Configure git safedir for the phabricator deploy repo.
# Without it can't run "git status" in /srv/phab and we
# get side effect problems such as not displaying version info (Bug: T360756)
#
# The deploy directory is 2 symlinks away from /srv/phab and changes on every scap deploy.

# [phab1004:/] $ readlink /srv/phab
# /srv/deployment/phabricator/deployment
# [phab1004:/] $ readlink /srv/deployment/phabricator/deployment
# deployment-cache/revs/0df351e7e648329c80d3a4dae674b62c5f1b175d
#
# That's why just using git::systemconfig with /srv/phab won't work.
#
# We also don't want to use '*' and set every single dir on the server as safedir.
# While we control the server and don't have manual git users it still seems ugly to do that.
#
# We can't get the actual target in puppet code either and we can't use the result
# of a shell command within puppet. So we are doing it with this bash script.
#
# We are writing into /etc/gitconfig.d/ and run git-update-config emulating what our own
# git::systemconfig does as well so we don't conflict with it.
# If we would directly run git config to write into /etc/gitconfig it would be overwritten
# next time another config changes.
#
link=$(/usr/bin/readlink -f /srv/phab)
/usr/bin/git config -f /etc/gitconfig.d/10-phab-deploy-safedir.gitconfig --add safe.directory $link
