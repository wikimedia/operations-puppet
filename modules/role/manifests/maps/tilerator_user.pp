#
# Create postgresql users for tilerator
#
# This is extracted to reduce a bit of duplication and to be used as a pseudo
# loop with `create_resources`. It might make sense to refactor this once we
# activate puppet future parser. It might also make sense to expose higher
# level abstractions in the postgresql module itself.
#
define role::maps::tilerator_user (
    $ip_address,
    $password,
    $postgres_tile_storage,
) {
    postgresql::user { "tilerator-gis@${title}":
        user     => 'tilerator',
        password => $password,
        database => 'gis',
        cidr     => "${ip_address}/32",
    }
    if $postgres_tile_storage {
        postgresql::user { "tilerator-tiles@${title}":
            user     => 'tilerator',
            password => $password,
            database => 'tiles',
            cidr     => "${ip_address}/32",
        }
    }
}
