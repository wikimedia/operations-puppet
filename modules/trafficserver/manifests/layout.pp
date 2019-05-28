define trafficserver::layout(
    Trafficserver::Paths $paths,
    Array[Stdlib::Absolutepath] $bins = [
                                            '/usr/bin/traffic_crashlog', '/usr/bin/traffic_ctl', '/usr/bin/traffic_layout',
                                            '/usr/bin/traffic_logcat', '/usr/bin/traffic_logstats',
                                            '/usr/bin/traffic_manager','/usr/bin/traffic_server', '/usr/bin/traffic_top',
                                            '/usr/bin/traffic_via', '/usr/bin/tspush'
                                        ],
    Array[Stdlib::Absolutepath] $sbins = [],
) {
    if !defined(File[$paths['base_path']]) {
        file { $paths['base_path']:
            ensure => directory,
            owner  => $trafficserver::user,
            mode   => '0755',
        }
    }

    file { "/etc/trafficserver/${title}-layout.yaml":
        ensure  => file,
        owner   => $trafficserver::user,
        mode    => '0400',
        content => template('trafficserver/layout.yaml.erb'),
        require => Package['trafficserver'],
    }

    file { $paths['prefix']:
        ensure  => directory,
        owner   => 'trafficserver',
        mode    => '0555',
        require => File[$paths['base_path']],
    }

    file { "${paths['prefix']}/runroot.yaml":
        ensure  => file,
        owner   => $trafficserver::user,
        mode    => '0400',
        content => template('trafficserver/layout.yaml.erb'),
        require => File[$paths['prefix']],
    }

    file { $paths['bindir']:
        ensure  => directory,
        owner   => $trafficserver::user,
        mode    => '0555',
        require => File[$paths['prefix']],
    }

    # populate bindir with symlinks to $bins
    $bins.each |Stdlib::Absolutepath $bin| {
        $filename = basename($bin)
        file { "${paths['bindir']}/${filename}":
            ensure  => link,
            target  => $bin,
            require => File[$paths['bindir']],
        }
    }

    file { $paths['sbindir']:
        ensure  => directory,
        owner   => $trafficserver::user,
        mode    => '0555',
        require => File[$paths['prefix']],
    }

    # populate sbindir with symlinks to $sbins
    $sbins.each |Stdlib::Absolutepath $sbin| {
        $filename = basename($sbin)
        file { "${paths['sbindir']}/${filename}":
            ensure  => link,
            target  => $sbin,
            require => File[$paths['sbindir']],
        }
    }

    file { $paths['sysconfdir']:
        ensure  => directory,
        owner   => $trafficserver::user,
        mode    => '0555',
        require => File[$paths['prefix']],
    }

    file { $paths['includedir']:
        ensure  => directory,
        owner   => $trafficserver::user,
        mode    => '0555',
        require => File[$paths['prefix']],
    }

    file { $paths['runtimedir']:
        ensure  => directory,
        owner   => $trafficserver::user,
        mode    => '0755',
        require => File[$paths['localstatedir']],
    }

    file { $paths['logdir']:
        ensure  => directory,
        owner   => $trafficserver::user,
        mode    => '0755',
        require => File[$paths['localstatedir']],
    }

    file { $paths['localstatedir']:
        ensure  => directory,
        owner   => $trafficserver::user,
        mode    => '0755',
        require => File[$paths['prefix']],
    }

    file { $paths['cachedir']:
        ensure  => directory,
        owner   => $trafficserver::user,
        mode    => '0755',
        require => File[$paths['localstatedir']],
    }
}
