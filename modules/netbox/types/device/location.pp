# SPDX-License-Identifier: Apache-2.0
type Netbox::Device::Location = Variant[
    Netbox::Device::Location::BareMetal,
    Netbox::Device::Location::Virtual,
]
