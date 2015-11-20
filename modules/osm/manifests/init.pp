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
        owner  => 'osmupdater',
        group  => 'osm',
        mode   => '0775',
    }
}
