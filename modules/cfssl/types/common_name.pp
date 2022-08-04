# SPDX-License-Identifier: Apache-2.0
# this type is a mostly Stdlib::Host however we add support for wildcard domains
type Cfssl::Common_name = Variant[
    Wmflib::Host::Wildcard,
    Wmflib::DNS::Srv,
    Stdlib::Host,
]
