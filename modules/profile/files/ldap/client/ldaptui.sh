#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
export BITU_LDAP_CONFIG_PATH=/etc/ldapui/config.json
/srv/ldapui/.venv/bin/python /srv/ldapui/ldaptui.py
