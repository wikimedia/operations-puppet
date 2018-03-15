class openstack::neutron::l3_agent(
    $version,
    ) {

    package {'neutron-l3-agent':
        ensure => 'present',
    }

    file { '/etc/neutron/l3_agent.ini':
            owner   => 'neutron',
            group   => 'neutron',
            mode    => '0640',
            content => template("openstack/${version}/neutron/l3_agent.ini.erb"),
            require => Package['neutron-l3-agent'];
    }

    service {'neutron-l3-agent':
        ensure  => 'running',
        require => Package['neutron-l3-agent'],
    }
}
