#

class osm {

    # osm2pgsql 0.90 is only available on jessie at the moment
    # there is no need for 0.90 on labs machines (precise)
    if os_version('debian == jessie') {
        apt::pin { 'osm2pgsql':
            pin      => 'release a=jessie-backports',
            priority => '1001',
            before   => Package['osm2pgsql'],
        }
    }

    # require_package creates a dynamic intermediate class that makes declaring
    # dependencies a bit strange. Let's use package directly here.
    if !defined(Package['osm2pgsql']) {
        package { 'osm2pgsql':
            ensure => 'present',
        }
    }

    require_package('osmosis')
}
