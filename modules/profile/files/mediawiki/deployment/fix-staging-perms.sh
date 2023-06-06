#!/bin/bash
# Fixes permissions on /srv/mediawiki-staging and /srv/patches.

set -euf
set -o pipefail

config_file=/usr/local/etc/fix-staging-perms.sh
# shellcheck disable=SC1090
source $config_file

# When deployment_group is unset or null: exit and print the message
group=${deployment_group:?"'deployment_group' must be set in $config_file"}

# Get root if we don't have it.
# Group 'deployment' should have sudo perms for this.
[[ "$UID" == 0 ]] || exec sudo "$0" "$@"

# All files and directories should be group-writable.
chmod -R g+w /srv/mediawiki-staging
chmod -R g+w /srv/patches

# Files and directories in the staging dir should have group ownership of deployment.
find /srv/mediawiki-staging -not -group "$group" -print0 | xargs -0 -r chgrp "$group"

# Files and directories in the patches repository should have group ownership of deployment
find /srv/patches -not -group "$group" -print0 | xargs -0 -r chgrp "$group"
