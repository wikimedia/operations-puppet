#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

[[ $HOSTNAME =~ wdqs2.* ]] && sleep $[ ( $RANDOM % 600 )  + 1 ] && sudo systemctl restart wdqs-blazegraph || echo "Not a codfw wdqs host, skipping"
