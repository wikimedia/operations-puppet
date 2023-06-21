# SPDX-License-Identifier: Apache-2.0
type Netbox::Device::Network = Struct[{
    ipv4                     => Stdlib::IP::Address::V4,
    primary_fqdn             => Stdlib::Fqdn,
    role                     => Netbox::Device::Network::Role,
    site                     => Wmflib::Sites,
    Optional['manufacturer'] => String[1],
    Optional['alarms']       => Boolean,
    Optional['ipv6']         => Stdlib::IP::Address::V6
}]
