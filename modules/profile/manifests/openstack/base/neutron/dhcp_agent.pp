class profile::openstack::base::neutron::dhcp_agent(
    $version = lookup('profile::openstack::base::version'),
    $dhcp_domain = lookup('profile::openstack::base::nova::dhcp_domain'),
    $report_interval = lookup('profile::openstack::base::neutron::report_interval'),
    ) {

    class {'::openstack::neutron::dhcp_agent':
        version         => $version,
        dhcp_domain     => $dhcp_domain,
        report_interval => $report_interval,
    }
    contain '::openstack::neutron::dhcp_agent'
}
