#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
#
# Copyright 2018 Emanuele Rocca
# Copyright 2018 Wikimedia Foundation, Inc.

res="$(/usr/bin/traffic_server -C verify_config 2>&1 | grep 'ERROR')"

if [ -z "$res" ]; then
    echo "OK: configuration valid"
    exit 0
else
    echo "WARNING: $res"
    exit 1
fi
