class openstack::neutron::linuxbridge_agent(
    $version,
    $network_flat_interface,
    $network_flat_name,
    ) {

    include openstack::nova::compute::kmod

    $packages = [
        'neutron-linuxbridge-agent',
        'libosinfo-1.0-0',
    ]

    package { $packages:
        ensure => 'present',
    }

    file { '/etc/neutron/plugins/ml2/linuxbridge_agent.ini':
        owner   => 'root',
        group   => 'root',
        mode    => '0744',
        content => template("openstack/${version}/neutron/plugins/ml2/linuxbridge_agent.ini.erb"),
        require => Package['neutron-linuxbridge-agent'],
    }

    file { '/etc/neutron/plugins/linuxbridge':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0744',
        require => File['/etc/neutron/plugins/ml2/linuxbridge_agent.ini'],
    }

    file { '/etc/neutron/plugins/linuxbridge/linuxbridge_conf.ini':
        ensure  => 'link',
        target  => '/etc/neutron/plugins/ml2/linuxbridge_agent.ini',
        require => File['/etc/neutron/plugins/linuxbridge'],
    }

    service {'neutron-linuxbridge-agent':
        ensure  => 'running',
        require => Package['neutron-linuxbridge-agent'],
    }
}
