class base::tcptweaks {
    Class[base::puppet] -> Class[base::tcptweaks]

    # unneeded since Linux 2.6.39, i.e. Ubuntu 11.10 Oneiric Ocelot
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '11.10') < 0 {
        file { '/etc/network/if-up.d/initcwnd':
            ensure  => present,
            content => template('base/initcwnd.erb'),
            mode    => '0555',
            owner   => 'root',
            group   => 'root',
        }

        exec { '/etc/network/if-up.d/initcwnd':
            require     => File['/etc/network/if-up.d/initcwnd'],
            subscribe   => File['/etc/network/if-up.d/initcwnd'],
            refreshonly => true,
        }
    } else {
        file { '/etc/network/if-up.d/initcwnd':
            ensure  => absent,
        }
    }
}