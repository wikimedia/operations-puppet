#!/bin/bash
set -eu

export SSH_AUTH_SOCK="/run/keyholder/proxy.sock"
META_MONITORING="root@wikitech-static.wikimedia.org"
CONTACTS_FILE="/etc/check_icinga/contacts.yaml"

generate-check-icinga-contacts | ssh "${META_MONITORING}" "cat - > ${CONTACTS_FILE}.new"
ssh "${META_MONITORING}" "diff ${CONTACTS_FILE} ${CONTACTS_FILE}.new" | cat
if [[ "${PIPESTATUS[0]}" -eq "0" ]]; then
    echo "No new contacts to sync. Aborting."
    exit 0
fi

ssh "${META_MONITORING}" "/usr/local/bin/check_icinga_validate_config --contacts ${CONTACTS_FILE}.new" | cat
if [[ "${PIPESTATUS[0]}" -ne "0" ]]; then
    echo "Failed validation of new contacts file. Aborting."
    ssh "${META_MONITORING}" "rm -fv ${CONTACTS_FILE}.new"
    exit 1
fi

ssh "${META_MONITORING}" "mv -fv ${CONTACTS_FILE}.new ${CONTACTS_FILE}"
ssh "${META_MONITORING}" "/usr/local/bin/check_icinga_validate_config"
echo "Successfully synced new configuration"
