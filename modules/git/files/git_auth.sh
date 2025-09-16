#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

# Intended to be called as an askpass method for git.
# Normally used by setting the GIT_ASKPASS environment variable.
# See: https://git-scm.com/docs/gitcredentials
case "$1" in
    Username*) exec echo "private" ;;
    Password*) exec echo "$GIT_AUTH_TOKEN" ;;
esac
