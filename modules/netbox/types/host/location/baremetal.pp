# SPDX-License-Identifier: Apache-2.0
type Netbox::Host::Location::BareMetal = Struct[{
    # should at some point have a Wmflib::Site
    site    => String[5,5],
    row     => String[2],
    rack    => String[2],
}]
