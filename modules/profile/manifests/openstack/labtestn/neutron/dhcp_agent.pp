class profile::openstack::labtestn::neutron::dhcp_agent(
    $version = hiera('profile::openstack::labtestn::version'),
    $dhcp_domain = hiera('profile::openstack::labtestn::nova::dhcp_domain'),
    $report_interval = hiera('profile::openstack::labtestn::neutron::report_interval'),
    ) {

    require ::profile::openstack::labtestn::clientlib
    require ::profile::openstack::labtestn::neutron::common
    class {'profile::openstack::base::neutron::dhcp_agent':
        version         => $version,
        dhcp_domain     => $dhcp_domain,
        report_interval => $report_interval,
    }
    contain 'profile::openstack::base::neutron::dhcp_agent'
}
