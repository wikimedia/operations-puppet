#

class osm::db($ensure='present') {
    package { [
        'osm2pgsql',
        'osmosis',
        ]:
        ensure => $ensure,
    }
}
