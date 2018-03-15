class profile::openstack::labtestn::neutron::ml2(
    $version = hiera('profile::openstack::labtestn::version'),
    $network_flat_interface = hiera('profile::openstack::labtestn::neutron::network_flat_interface'),
    ) {

    require ::profile::openstack::labtestn::clientlib
    require ::profile::openstack::labtestn::neutron::common
    class {'::profile::openstack::base::neutron::ml2':
        version                => $version,
        network_flat_interface => $network_flat_interface,
    }
    contain '::profile::openstack::base::neutron::ml2'
}
