#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
KIBANA_VERSION=$(jq -r ".version" /usr/share/kibana/package.json)
PHATALITY_PKG="/srv/deployment/releng/phatality/deploy/phatality-$KIBANA_VERSION.zip"
/usr/bin/sudo -u kibana /usr/share/kibana/bin/kibana-plugin remove phatality
/usr/bin/sudo -u kibana /usr/share/kibana/bin/kibana-plugin install file://$PHATALITY_PKG