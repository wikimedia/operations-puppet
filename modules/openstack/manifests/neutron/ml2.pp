class openstack::neutron::ml2(
    $version,
    ) {

    package {'neutron-linuxbridge-agent':
        ensure => 'present',
    }

    file { '/etc/neutron/plugins/ml2/ml2_conf.in':
        content => template("openstack/${version}/neutron/plugins/ml2/ml2_conf.ini.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => '0744',
        require => Package['neutron-linuxbridge-agent'];
    }

    file { '/etc/neutron/plugins/ml2/linuxbridge_agent.ini':
        content => template("openstack/${version}/neutron/plugins/ml2/linuxbridge_agent.ini.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => '0744',
        require => Package['neutron-linuxbridge-agent'];
    }
}
