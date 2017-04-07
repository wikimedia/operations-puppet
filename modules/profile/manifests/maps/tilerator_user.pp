#
# Create postgresql users for tilerator
#
# This is extracted to reduce a bit of duplication and to be used as a pseudo
# loop with `create_resources`. It might make sense to refactor this once we
# activate puppet future parser. It might also make sense to expose higher
# level abstractions in the postgresql module itself.
#
define profile::maps::tilerator_user (
    $ip_address,
    $password,
) {
    postgresql::user { "tilerator@${title}":
        user     => 'tilerator',
        password => $password,
        database => 'all',
        cidr     => "${ip_address}/32",
    }
}
