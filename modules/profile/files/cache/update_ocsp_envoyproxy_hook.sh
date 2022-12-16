#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

# Skip the reload if the service is not active. this happens
# when update-ocsp-all execution is triggered by ExecStartPre
# on the envoyproxy service unit
if /bin/systemctl is-active envoyproxy --quiet; then
    /bin/systemctl reload envoyproxy > /dev/null 2>&1 || exit 99
fi
