#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -eu -o pipefail

KIBANA_VERSION=$(jq -r ".version" /usr/share/kibana/package.json)
PHATALITY_PKG="/srv/deployment/releng/phatality/deploy/phatality-$KIBANA_VERSION.zip"

mapfile -t plugins < <(/usr/bin/sudo -u kibana /usr/share/kibana/bin/kibana-plugin list phatality)

for plugin_line in "${plugins[@]}"
do
    if [[ $plugin_line =~ ^phatality ]]; then
        echo "Removing existing phatality plugin before installation"
        /usr/bin/sudo -u kibana /usr/share/kibana/bin/kibana-plugin remove phatality
    fi
done

/usr/bin/sudo -u kibana /usr/share/kibana/bin/kibana-plugin install "file://$PHATALITY_PKG"
