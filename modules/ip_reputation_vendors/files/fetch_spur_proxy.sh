#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#

curl --get "https://exports.spur.us/v1/feeds/anonymous-residential" \
     --data-urlencode "output=mmdb" \
     --data-urlencode "fields=network,callbackProxy" \
     -H "Token: $SPUR_TOKEN" \
     -o "$1"

