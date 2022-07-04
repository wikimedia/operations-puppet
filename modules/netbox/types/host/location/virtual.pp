# SPDX-License-Identifier: Apache-2.0
type Netbox::Host::Location::Virtual = Struct[{
    site           => Wmflib::Sites,
    ganeti_cluster => String[1],
    ganeti_group   => String[1],

}]
