class openstack::neutron::dhcp_agent::mitaka(
    $dhcp_domain,
    $report_interval,
) {
    class { "openstack::neutron::dhcp_agent::mitaka::${::lsbdistcodename}": }

    file { '/etc/neutron/dhcp_agent.ini':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        content => template('openstack/mitaka/neutron/dhcp_agent.ini.erb'),
        require => Package['neutron-common'];
    }

    file { '/etc/neutron/dnsmasq-neutron.conf':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        content => template('openstack/mitaka/neutron/dnsmasq-neutron.conf.erb'),
        require => Package['neutron-common'];
    }
}
