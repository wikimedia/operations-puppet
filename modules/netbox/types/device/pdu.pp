# SPDX-License-Identifier: Apache-2.0
type Netbox::Device::PDU = Struct[{
    manufacturer             => String[1],
    model                    => String[1],
    fqdn                     => Stdlib::Fqdn,
    location                 => Netbox::Device::Location,
}]
