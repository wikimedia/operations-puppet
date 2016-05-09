#

class osm (
    $ensure = present,
){

    # osm2pgsql 0.90 is only available on jessie at the moment
    # there is no need for 0.90 on labs machines (precise)
    $osm2pgsql_ensure = $ensure ? {
        'present' => os_version('Debian >= Jessie') ? {
            true => '0.90.0+ds-1~bpo8+1',
            default => 'present',
        },
        default   => $ensure,
    }

    # Can't use require_package here because we need to specify version
    # from jessie-backports:
    if !defined(Package['osm2pgsql']) {
        package { 'osm2pgsql':
            ensure => $osm2pgsql_ensure,
        }
    }

    if !defined(Package['osmosis']) {
        package { 'osmosis':
            ensure => $ensure,
        }
    }
}
