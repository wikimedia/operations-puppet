#!/usr/bin/bash
# SPDX-License-Identifier: Apache-2.0

# Set up a bare git repository cloning 'branch' from 'url' into 'git_dir'
# All pushes to this repository will be also pushed to the git repo at 'push_path'

# This enables users to treat their Pontoon server as a git remote, pushing to
# repos (e.g. puppet.git) as we do with Gerrit/Gitlab.

set -e
set -u

branch=$1
url=$2
git_dir=$3
push_path=$4

hooks="post-receive pre-receive"

if [ ! -d "$git_dir" ]; then
  git clone --bare --branch "$branch" "$url" "$git_dir"
fi

for hook in $hooks; do
  hook_path=/srv/git/operations/puppet/modules/pontoon/files/bootstrap/git-${hook}.sh
  repo_hook_path="$git_dir/hooks/${hook}"
  if [ ! -e "$repo_hook_path" ] || [ "$hook_path" -nt "$repo_hook_path" ]; then
    install -v -m755 "$hook_path" "$repo_hook_path"
  fi
done

GIT_DIR=$git_dir git remote set-url origin "$push_path"

sudo git config --global --add safe.directory "$push_path"

exit 0
