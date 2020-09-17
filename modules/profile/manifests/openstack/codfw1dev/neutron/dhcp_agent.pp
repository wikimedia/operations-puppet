class profile::openstack::codfw1dev::neutron::dhcp_agent(
    $version = lookup('profile::openstack::codfw1dev::version'),
    $dhcp_domain = lookup('profile::openstack::codfw1dev::nova::dhcp_domain'),
    $report_interval = lookup('profile::openstack::codfw1dev::neutron::report_interval'),
    ) {

    require ::profile::openstack::codfw1dev::neutron::common
    class {'profile::openstack::base::neutron::dhcp_agent':
        version         => $version,
        dhcp_domain     => $dhcp_domain,
        report_interval => $report_interval,
    }
    contain 'profile::openstack::base::neutron::dhcp_agent'
}
