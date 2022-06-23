# SPDX-License-Identifier: Apache-2.0
type Netbox::Host::Location::Virtual = Struct[{
    # should at some point have a Wmflib::Site
    site           => String[5,5],
    ganeti_cluster => String[1],
}]
