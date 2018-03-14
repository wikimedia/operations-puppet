class openstack::neutron::l3_agent(
    $version,
    ) {

    package {'neutron-l3-agent':
        ensure => 'present',
    }

    file { '/etc/neutron/l3_agent.ini':
            owner   => 'root',
            group   => 'root',
            mode    => '0440',
            content => template("openstack/${version}/neutron/l3_agent.ini.erb"),
            require => Package['neutron-l3-agent'];
    }
}
