# SPDX-License-Identifier: Apache-2.0
type Netbox::Host::Location::BareMetal = Struct[{
    site    => Wmflib::Sites,
    row     => String[2],
    rack    => String[2],
}]
