#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
set -ue
PATH=/usr/bin

environment=$1

if [[ $environment != 'dev' ]]; then
	git_dir=/srv/git/operations/puppet/.git
	git --git-dir="${git_dir}" log -1 --pretty='(%h) %cn - %s' --first-parent "${environment}" --
else
	# In the dev environment we may have a dirty tree, so for now always
	# return dev
	printf 'dev\n'
fi
