#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

MAP_FILE="/etc/haproxy/novaproxy.map"

ORIGINAL_FILE=""
if [ -f "$MAP_FILE" ]; then
	ORIGINAL_FILE="$(cat $MAP_FILE)"
fi

mariadb -Ns -e "SELECT domain, backend_url FROM route ORDER BY domain;" | sponge "$MAP_FILE"

if [ "$(cat $MAP_FILE)" != "$ORIGINAL_FILE" ]; then
	echo "Mapping has changed, reloading HAProxy"
	systemctl reload haproxy.service
fi
