# SPDX-License-Identifier: Apache-2.0
# @summary profile to load and access common netbox data
# @param mgmt hash of managment hosts
class profile::netbox::data (
    Hash[Stdlib::Host, Netbox::Host::Location::BareMetal] $mgmt = lookup('profile::netbox::data::mgmt')
) {}

