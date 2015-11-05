#

class osm($ensure='present') {
    package { [
        'osm2pgsql',
        'osmosis',
        ]:
        ensure => $ensure,
    }

    file { '/srv/downloads':
        ensure => 'directory',
        owner  => 'postgres',
        group  => 'postgres',
        mode   => '0755',
    }
}
