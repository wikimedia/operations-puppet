class profile::openstack::base::neutron::dhcp_agent(
    $version = hiera('profile::openstack::base::version'),
    ) {

    class {'::openstack::neutron::dhcp_agent':
        version => $version,
    }
    contain '::openstack::neutron::dhcp_agent'
}
