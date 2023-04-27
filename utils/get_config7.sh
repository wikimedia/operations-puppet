#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
set -ue
PATH=/usr/bin

environment=$1
git_dir=/srv/git/operations/puppet/.git
git --git-dir="${git_dir}" log -1 --pretty='(%h) %cn - %s' --first-parent "${environment}"
