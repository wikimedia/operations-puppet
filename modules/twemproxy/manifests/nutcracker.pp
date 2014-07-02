class twemproxy::nutcracker ($config, $server_list) {
    tag 'twemproxy'
    package {'nutcracker': }

    file { '/etc/default/nutcracker':
        ensure  => present,
        content => 'DAEMON_OPTS="--config /etc/nutcracker/config.yml"',
        require => Package['nutcracker'],
    }

    file { '/etc/nutcracker/nutcracker.yml':
        ensure  => present,
        mode    => '0444',
        content => template('twemproxy/config.yml.erb'),
        require => File['/etc/default/nutcracker'],
        notify  => Service['twemproxy'],
    }
    # this needs to have the same name as the old twemproxy service,
    # for compat reasons
    service { 'twemproxy':
        ensure   => running,
        name     => 'nutcracker',
        provider => upstart,
    }
}
