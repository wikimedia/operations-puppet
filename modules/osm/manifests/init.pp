#

class osm {

    # Can't use require_package here because we need to specify version
    # from jessie-backports:
    if !defined(Package['osm2pgsql']) {
        package { 'osm2pgsql':
            ensure => '0.90.0+ds-1~bpo8+1',
        }
    }

    require_package('osmosis')
}
