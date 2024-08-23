#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

# This hook will be installed in the user's HOME puppet.git and
# private.git bare repositories to update the canonical git checkouts in
# /srv/git. Effectively "syncing" the user's puppet/private repos to /srv/git

# On receiving (i.e. the user pushes to this bare repo) the hook will look up
# the repo's "origin" remote and update it to match what has been just pushed
# here.

set -e
set -u

#git_debug='GIT_TRACE=2 GIT_TRACE_PERFORMANCE=2 GIT_TRACE_SETUP=2 GIT_TRACE_SHALLOW=2 GIT_TRACE_PACKET=2 GIT_TRACE_PACK_ACCESS=2'
git_debug=''

if [ -n "$git_debug" ]; then
  set -x
fi

source_dir=$PWD
dest_dir=$(git remote get-url origin)
cd "$dest_dir"
echo "Pulling $source_dir into $dest_dir"
sudo env $git_debug git fetch --keep --no-auto-gc "$source_dir"

fetch_head=$(sudo env $git_debug git rev-parse FETCH_HEAD)
reflog_action="$USER moved from $fetch_head via git push"
sudo env GIT_REFLOG_ACTION="$reflog_action" $git_debug git checkout -B production FETCH_HEAD
