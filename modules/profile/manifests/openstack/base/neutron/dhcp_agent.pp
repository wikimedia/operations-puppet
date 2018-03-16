class profile::openstack::base::neutron::dhcp_agent(
    $version = hiera('profile::openstack::base::version'),
    $dhcp_domain = hiera('profile::openstack::base::nova::dhcp_domain'),
    ) {

    class {'::openstack::neutron::dhcp_agent':
        version     => $version,
        dhcp_domain => $dhcp_domain
    }
    contain '::openstack::neutron::dhcp_agent'
}
