class profile::openstack::base::neutron::linuxbridge_agent(
    $version = hiera('profile::openstack::base::version'),
    $network_flat_interface = hiera('profile::openstack::base::neutron::network_flat_interface'),
    $bridge_mappings = hiera('profile::openstack::base::neutron::bridge_mappings'),
    $internal_bridge =  hiera('profile::openstack::base::neutron::internal_bridge'),
    ) {

    class {'::openstack::neutron::linuxbridge_agent':
        version                => $version,
        network_flat_interface => $network_flat_interface,
        bridge                 => $internal_bridge,
        bridge_mappings        => $bridge_mappings,
    }
    contain '::openstack::neutron::linuxbridge_agent'
}
