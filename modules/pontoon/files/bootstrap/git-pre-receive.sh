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
if ! sudo env $git_debug git diff-index --quiet HEAD --; then
  echo
  echo "The canonical git repository at $dest_dir is not clean:"
  sudo env $git_debug git diff-index --name-status HEAD --
  echo
  exit 1
fi
