# SPDX-License-Identifier: Apache-2.0
# @summary profile to load and access common netbox data
# @param mgmt hash of managment hosts
# @param network_devices hash of network_devices
# @param prefixes hash of prefixes
class profile::netbox::data (
    # TODO: if this becomes to much data we should restrict what we load
    Hash[Stdlib::Host, Netbox::Device::Location::BareMetal] $mgmt         = lookup('profile::netbox::data::mgmt'),
    Hash[String[3], Netbox::Device::Network]                $network_devices = lookup('profile::netbox::data::network_devices'),
    Hash[Stdlib::IP::Address, Netbox::Prefix]               $prefixes       = lookup('profile::netbox::data::prefixes'),
) {
  # requires_realm('production')
}
