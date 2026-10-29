#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

MAP_FILE="/etc/haproxy/novaproxy.map"
DISABLED_MAP_FILE="/etc/haproxy/disabled.map"

ORIGINAL_HASH="$(sha256sum $MAP_FILE $DISABLED_MAP_FILE)"

mariadb -Ns -e "SELECT domain, backend_url FROM route WHERE status = 0 ORDER BY domain;" | sponge "$MAP_FILE"
mariadb -Ns -e "SELECT domain FROM route WHERE status = 1 ORDER BY domain;" | sponge "$DISABLED_MAP_FILE"

if [ "$(sha256sum $MAP_FILE $DISABLED_MAP_FILE)" != "$ORIGINAL_HASH" ]; then
	echo "Mapping has changed, reloading HAProxy"
	systemctl reload haproxy.service
fi
