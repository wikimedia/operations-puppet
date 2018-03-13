class profile::openstack::labtestn::neutron::service(
    $version = hiera('profile::openstack::labtestn::version'),
    ) {

    require ::profile::openstack::labtestn::clientlib
    class {'::profile::openstack::base::neutron::service':
        version => $version,
    }
    contain '::profile::openstack::base::neutron::service'
}
