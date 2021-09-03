#!/usr/bin/env bash

[[ $HOSTNAME =~ wdqs2.* ]] && sudo systemctl restart wdqs-blazegraph || echo "Not a codfw wdqs host, skipping"
