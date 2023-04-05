# SPDX-License-Identifier: Apache-2.0
type Netbox::Device::Location::BareMetal = Struct[{
    site    => Wmflib::Sites,
    row     => String[2],
    rack    => String[2],
}]
