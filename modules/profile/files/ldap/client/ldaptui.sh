#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
export BITU_LDAP_CONFIG_PATH=/etc/ldaptui/config.json
/srv/ldaptui/.venv/bin/python /srv/ldaptui/ldaptui.py
