class openstack::neutron::dhcp_agent(
    $version,
    $dhcp_domain,
    ) {

    package {'neutron-dhcp-agent':
        ensure => 'present',
    }

    file { '/etc/neutron/dhcp_agent.ini':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        content => template("openstack/${version}/neutron/dhcp_agent.ini.erb"),
        require => Package['neutron-common'];
    }

    file { '/etc/neutron/dnsmasq-neutron.conf':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        content => template("openstack/${version}/neutron/dnsmasq-neutron.conf.erb"),
        require => Package['neutron-common'];
    }

    service {'neutron-dhcp-agent':
        ensure  => 'running',
        require => Package['neutron-dhcp-agent'],
    }
}
