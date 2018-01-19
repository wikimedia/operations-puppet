class profile::openstack::labtestn::nova::common(
    $version = hiera('profile::openstack::labtestn::version'),
    ) {

    require ::profile::openstack::labtestn::cloudrepo
    class {'::profile::openstack::base::nova::common::neutron':
        version => $version,
    }
    contain '::profile::openstack::base::nova::common::neutron'
}
