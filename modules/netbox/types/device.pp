# SPDX-License-Identifier: Apache-2.0
type Netbox::Device = Struct[{
    site    => Wmflib::Sites,
    row     => String[2],
    role    => String[2],
    rack    => String[2],
}]
