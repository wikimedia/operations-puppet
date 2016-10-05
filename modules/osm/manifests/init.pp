#

class osm (
    $ensure = present,
){

    # osm2pgsql 0.90 is only available on jessie at the moment
    # there is no need for 0.90 on labs machines (precise)
    if os_version('Debian == Jessie') {
        apt::pin { 'osm2pgsql':
            pin      => 'release a=jessie-backports',
            priority => '1001',
            before   => Package['osm2pgsql'],
        }
    }

    require_package('osm2pgsql', 'osmosis')
}
