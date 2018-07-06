class profile::openstack::eqiad1::neutron::dhcp_agent(
    $version = hiera('profile::openstack::eqiad1::version'),
    $dhcp_domain = hiera('profile::openstack::eqiad1::nova::dhcp_domain'),
    ) {

    require ::profile::openstack::eqiad1::clientlib
    require ::profile::openstack::eqiad1::neutron::common
    class {'profile::openstack::base::neutron::dhcp_agent':
        version     => $version,
        dhcp_domain => $dhcp_domain,
    }
    contain 'profile::openstack::base::neutron::dhcp_agent'
}
