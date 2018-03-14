class openstack::neutron::dhcp_agent(
    $version,
    ) {

    package {'neutron-dhcp-agent':
        ensure => 'present',
    }

    file { '/etc/neutron/dhcp_agent.ini':
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            content => template("openstack/${version}/neutron/dhcp_agent.ini.erb"),
            require => Package['neutron-common'];
    }
}
