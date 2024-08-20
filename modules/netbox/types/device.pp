# SPDX-License-Identifier: Apache-2.0
type Netbox::Device = Struct[{
    site    => Wmflib::Sites,
    row     => String[2],
    role    => Optional[String[2]],  # Optional only for the transition period
    rack    => String[2],
}]
