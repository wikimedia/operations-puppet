class openstack::neutron::dhcp_agent::wallaby(
    $dhcp_domain,
    $report_interval,
) {
    class { "openstack::neutron::dhcp_agent::wallaby::${::lsbdistcodename}": }

    file { '/etc/neutron/dhcp_agent.ini':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        content => template('openstack/wallaby/neutron/dhcp_agent.ini.erb'),
        require => Package['neutron-common'];
    }

    file { '/etc/neutron/dnsmasq-neutron.conf':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        content => template('openstack/wallaby/neutron/dnsmasq-neutron.conf.erb'),
        require => Package['neutron-common'];
    }
}
