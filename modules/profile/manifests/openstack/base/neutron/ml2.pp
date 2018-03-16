class profile::openstack::base::neutron::ml2(
    $version = hiera('profile::openstack::base::version'),
    $network_flat_interface = hiera('profile::openstack::base::neutron::network_flat_interface'),
    $network_flat_name = hiera('profile::openstack::base::neutron::network_flat_name'),
    ) {

    class {'::openstack::neutron::ml2':
        version                => $version,
        network_flat_interface => $network_flat_interface,
        network_flat_name      => $network_flat_name,
    }
    contain '::openstack::neutron::ml2'
}
