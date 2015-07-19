#

class osm($ensure='present') {
    package { [
        'osm2pgsql',
        'osmosis',
        ]:
        ensure => $ensure,
    }

    file { '/srv/downloads':
        ensure => 'present',
        owner => 'root',
        group => 'root',
        mode => 0777,
    }
}
