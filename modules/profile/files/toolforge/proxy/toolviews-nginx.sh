#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Process nginx access log data
#
# THIS FILE IS MANAGED BY PUPPET
set -e

/usr/local/bin/toolviews.py /var/log/nginx/access.log.1
