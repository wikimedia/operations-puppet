# SPDX-License-Identifier: Apache-2.0
type Netbox::Host::Location = Variant[
    Netbox::Host::Location::BareMetal,
    Netbox::Host::Location::Virtual,
]
