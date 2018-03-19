class profile::openstack::base::neutron::linuxbridge_agent(
    $version = hiera('profile::openstack::base::version'),
    $network_flat_interface = hiera('profile::openstack::base::neutron::network_flat_interface'),
    $network_flat_name = hiera('profile::openstack::base::neutron::network_flat_name'),
    ) {

    class {'::openstack::neutron::linuxbridge_agent':
        version                => $version,
        network_flat_interface => $network_flat_interface,
        network_flat_name      => $network_flat_name,
    }
    contain '::openstack::neutron::linuxbridge_agent'
}
