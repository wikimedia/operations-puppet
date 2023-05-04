# @summary Cloud VPS specific tweaks to the base Pontoon setup
# SPDX-License-Identifier: Apache-2.0
class profile::pontoon::provider::cloud_vps () {
    # In production we're explicitly purging isc-dhcp-client (8d58ccdbc8be6)
    # via 'profile::base::additional_purged_packages' variable.
    # To avoid fully overriding the variable, install a *different* dhcp client
    # here since it is required in Cloud VPS.
    ensure_packages(['dhcpcd5'])
}
