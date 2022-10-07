# SPDX-License-Identifier: Apache-2.0
#
# Create postgresql users for tilerator
#
# This is extracted to reduce a bit of duplication and to be used as a pseudo
# loop with `create_resources`. It might make sense to refactor this once we
# activate puppet future parser. It might also make sense to expose higher
# level abstractions in the postgresql module itself.
#
define profile::maps::tilerator_user (
    Stdlib::IP::Address $ip_address,
    String $password,
) {
    if $ip_address =~ Stdlib::IP::Address::Nosubnet {
        $_ip_address = "${ip_address}/32"
    } else {
        $_ip_address = $ip_address
    }
    postgresql::user { "tilerator@${title}":
        user     => 'tilerator',
        password => $password,
        database => 'all',
        cidr     => $_ip_address,
    }
}
