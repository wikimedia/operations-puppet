#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

set -e
set -u

#git_debug='GIT_TRACE=2 GIT_TRACE_PERFORMANCE=2 GIT_TRACE_SETUP=2 GIT_TRACE_SHALLOW=2 GIT_TRACE_PACKET=2 GIT_TRACE_PACK_ACCESS=2'
git_debug=''

if [ -n "$git_debug" ]; then
  set -x
fi

source_dir=$PWD
dest_dir=$(git remote get-url origin)
cd $dest_dir
git_status="$(sudo env $git_debug git status --porcelain)"
if test -n "$git_status"; then
  echo
  echo "$dest_dir is not clean (git status --porcelain):"
  echo $git_status
  echo
  echo
  echo "Make sure the repository at $dest_dir is clean before pushing."
  echo
  exit 1
fi
