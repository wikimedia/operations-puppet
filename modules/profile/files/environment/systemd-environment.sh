#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
systemd_vars=$(/usr/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)
if [ -n "${systemd_vars}" ]
then
    export $systemd_vars
fi
