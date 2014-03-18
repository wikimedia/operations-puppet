#

class osm::packages($ensure='present') {
    package { [
        'osm2pgsql',
        'osmosis',
        ]:
        ensure => $ensure,
    }
}
