#

class osm {

    # Use backports versions of osm2pgsql for improved memory handling and other updates
    if os_version('debian == jessie') {
        apt::pin { 'osm2pgsql':
            pin      => 'release a=jessie-backports',
            priority => '1001',
            before   => Package['osm2pgsql'],
        }
    } elsif os_version('debian == stretch') {
        apt::pin { 'osm2pgsql':
            pin      => 'release a=stretch-backports',
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
    require_package('osmium-tool')
    require_package('osmborder')
}
