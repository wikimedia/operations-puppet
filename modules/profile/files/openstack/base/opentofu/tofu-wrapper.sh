#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

if [ "$(id -u)" -ne 0 ]; then
    echo "tofu: please run as root"
    exit 1
fi

source /etc/tofu.env
exec /usr/bin/tofu "$@"
