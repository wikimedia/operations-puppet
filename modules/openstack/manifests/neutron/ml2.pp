class openstack::neutron::ml2(
    $version,
    $network_flat_interface,
    ) {

    include openstack::nova::compute::kmod

    $packages = [
        'neutron-linuxbridge-agent',
        'neutron-plugin-ml2',
    ]

    package { $packages:
        ensure => 'present',
    }

    file { '/etc/neutron/plugins/ml2/ml2_conf.ini':
        owner   => 'neutron',
        group   => 'root',
        mode    => '0744',
        content => template("openstack/${version}/neutron/plugins/ml2/ml2_conf.ini.erb"),
        require => Package['neutron-linuxbridge-agent'];
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
