class openstack::neutron::dhcp_agent(
    $version,
    $dhcp_domain,
    $report_interval,
    ) {

    class { "openstack::neutron::dhcp_agent::${version}":
        dhcp_domain     => $dhcp_domain,
        report_interval => $report_interval,
    }

    service {'neutron-dhcp-agent':
        ensure    => 'running',
        require   => Package['neutron-dhcp-agent'],
        subscribe => [
                      File['/etc/neutron/neutron.conf'],
                      File['/etc/neutron/dhcp_agent.ini'],
                      File['/etc/neutron/dnsmasq-neutron.conf'],
            ],
    }
}
