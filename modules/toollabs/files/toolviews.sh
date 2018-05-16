#!/usr/bin/env bash
# Process nginx access log data
#
# THIS FILE IS MANAGED BY PUPPET
set -e

/usr/local/bin/toolviews.py /var/log/nginx/access.log.1
