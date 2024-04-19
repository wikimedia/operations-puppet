class openstack::neutron::dhcp_agent(
    $version,
    $dhcp_domain,
    $report_interval,
    String[1] $interface_driver,
) {

    class { "openstack::neutron::dhcp_agent::${version}":
        dhcp_domain      => $dhcp_domain,
        report_interval  => $report_interval,
        interface_driver => $interface_driver,
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
