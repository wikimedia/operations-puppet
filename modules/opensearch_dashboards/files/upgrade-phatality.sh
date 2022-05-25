#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
DASHBOARDS_VERSION=$(jq -r ".version" /usr/share/opensearch-dashboards/package.json)
PHATALITY_PKG="/srv/deployment/releng/phatality/deploy/phatality-$DASHBOARDS_VERSION.zip"
/usr/bin/sudo -u opensearch-dashboards /usr/share/opensearch-dashboards/bin/opensearch-dashboards-plugin remove phatality
/usr/bin/sudo -u opensearch-dashboards /usr/share/opensearch-dashboards/bin/opensearch-dashboards-plugin install file://$PHATALITY_PKG
