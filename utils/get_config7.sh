#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
set -ue
PATH=/usr/bin

environment=$1

if [[ $environment != 'dev' ]]; then
	git_dir=/srv/git/operations/puppet/.git
	# %cN normalizes the committer using .mailmap
	git --git-dir="${git_dir}" log -1 --pretty='(%h) %cN - %s' --first-parent --
else
	# In the dev environment we may have a dirty tree, so for now always
	# return dev
	printf 'dev\n'
fi
