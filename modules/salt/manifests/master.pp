class salt::master(
    $salt_version='installed',
    $salt_interface=undef,
    $salt_worker_threads=undef,
    $salt_runner_dirs=['/srv/runners'],
    $salt_file_roots={'base'=>['/srv/salt']},
    $salt_pillar_roots={'base'=>['/srv/pillar']},
    $salt_ext_pillar={},
    $salt_reactor_root='/srv/reactors',
    $salt_reactor = {},
    $salt_auto_accept = false,
    $salt_peer={},
    $salt_peer_run={},
    $salt_nodegroups={},
    $salt_state_roots={'base'=>['/srv/salt']},
    $salt_module_roots={'base'=>['/srv/salt/_modules']},
    $salt_returner_roots={'base'=>['/srv/salt/_returners']},
){
    package { 'salt-master':
        ensure => $salt_version,
    }

    service { 'salt-master':
        ensure  => running,
        enable  => true,
        require => Package['salt-master'],
    }

    file { '/etc/salt/master':
        content => template('salt/master.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['salt-master'],
        require => Package['salt-master'],
    }

    file { $salt_runner_dirs:
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { $salt_reactor_root:
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    salt::master_environment{ 'base':
        salt_state_roots    => $salt_state_roots,
        salt_file_roots     => $salt_file_roots,
        salt_pillar_roots   => $salt_pillar_roots,
        salt_module_roots   => $salt_module_roots,
        salt_returner_roots => $salt_returner_roots,
    }

    sysctl::parameters { 'salt-master':
        values => {
            'net.core.somaxconn'          => 4096,
            'net.core.netdev_max_backlog' => 4096,
            'net.ipv4.tcp_mem'            => '16777216 16777216 16777216',
        }
    }
}
