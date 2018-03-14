class profile::openstack::labtestn::neutron::ml2(
    $version = hiera('profile::openstack::labtestn::version'),
    ) {

    require ::profile::openstack::labtestn::clientlib
    require ::profile::openstack::labtestn::neutron::common
    class {'::profile::openstack::base::neutron::ml2':
        version => $version,
    }
    contain '::profile::openstack::base::neutron::ml2'
}
