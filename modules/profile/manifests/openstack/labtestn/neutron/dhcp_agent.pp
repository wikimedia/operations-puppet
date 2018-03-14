class profile::openstack::labtestn::neutron::dhcp_agent(
    $version = hiera('profile::openstack::labtestn::version'),
    ) {

    require ::profile::openstack::labtestn::clientlib
    require ::profile::openstack::labtestn::neutron::common
    class {'profile::openstack::base::neutron::dhcp_agent':
        version => $version,
    }
    contain 'profile::openstack::base::neutron::dhcp_agent'
}
