# == Class: statsite::decommission
#
# Decommission statsite

class statsite::decommission {
    package { 'statsite':
        ensure => purged,
    }

    file { '/etc/statsite':
        ensure  => absent,
        recurse => true,
        purge   => true,
        force   => true,
    }

    if $::initsystem == 'upstart' {
        file { '/sbin/statsitectl':
            ensure => absent,
        }

        file { '/etc/init/statsite':
            ensure  => absent,
            recurse => true,
            purge   => true,
            force   => true,
        }

        file { '/etc/init/statsite.override':
            ensure  => absent,
        }

        service { 'statsite':
            ensure   => 'stopped',
            provider => 'base',
            restart  => '/sbin/statsitectl restart',
            start    => '/sbin/statsitectl start',
            status   => '/sbin/statsitectl status',
            stop     => '/sbin/statsitectl stop',
            before   => [ Package['statsite'],
                          File['/sbin/statsitectl'],
                          File['/etc/statsite'],
                          File['/etc/init/statsite'] ],
        }
    }
}
