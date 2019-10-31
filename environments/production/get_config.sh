#!/bin/sh
# We dont actully need the environment
# environment=$1
set -ue
PATH=/usr/bin

script_dir=$(dirname "$(realpath "$0")")
repo_dir=$(realpath "${script_dir}/../../.git")
git --git-dir "${repo_dir}" log -1 --pretty='(%h) %cn - %s'
