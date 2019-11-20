class openstack::neutron::dhcp_agent::ocata(
    $dhcp_domain,
    $report_interval,
) {
    class { "openstack::neutron::dhcp_agent::ocata::${::lsbdistcodename}": }

    file { '/etc/neutron/dhcp_agent.ini':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        content => template('openstack/ocata/neutron/dhcp_agent.ini.erb'),
        require => Package['neutron-common'];
    }

    file { '/etc/neutron/dnsmasq-neutron.conf':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0640',
        content => template('openstack/ocata/neutron/dnsmasq-neutron.conf.erb'),
        require => Package['neutron-common'];
    }
}
