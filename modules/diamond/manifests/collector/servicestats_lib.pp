# support class, to be include'd multiple times
class diamond::collector::servicestats_lib {
    diamond::collector { 'ServiceStats':
        source   => 'puppet:///modules/diamond/collector/servicestats.py',
        settings => {
          initsystem => $::initsystem,
        },
    }

    file { '/usr/share/diamond/collectors/servicestats/servicestats_lib.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/diamond/collector/servicestats_lib.py',
        require => Diamond::Collector['ServiceStats'],
    }

    file { '/etc/diamond/servicestats.d':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    package { ['python-psutil', 'python-configparser']:
        before => Diamond::Collector['ServiceStats'],
    }
}
