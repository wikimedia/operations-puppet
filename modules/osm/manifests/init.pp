#

class osm($ensure='present') {
    package { [
        'osm2pgsql',
        'osmosis',
        ]:
        ensure => $ensure,
    }
}
