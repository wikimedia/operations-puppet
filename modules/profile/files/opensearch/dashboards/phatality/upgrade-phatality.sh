#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -eu -o pipefail

DASHBOARDS_VERSION=$(jq -r ".version" /usr/share/opensearch-dashboards/package.json)
PHATALITY_PKG="/srv/deployment/releng/phatality/deploy/phatality-$DASHBOARDS_VERSION.zip"

mapfile -t plugins < <(/usr/share/opensearch-dashboards/bin/opensearch-dashboards-plugin list phatality)

for plugin_line in "${plugins[@]}"
do
    if [[ $plugin_line =~ ^phatality ]]; then
        echo "Removing existing phatality plugin before installation"
        /usr/bin/sudo -u opensearch-dashboards /usr/share/opensearch-dashboards/bin/opensearch-dashboards-plugin remove phatality
    fi
done

/usr/bin/sudo -u opensearch-dashboards /usr/share/opensearch-dashboards/bin/opensearch-dashboards-plugin install "file://$PHATALITY_PKG"
