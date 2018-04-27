class profile::openstack::labtestn::clientlib(
    $version = hiera('profile::openstack::labtestn::version'),
    ) {
    class {'profile::openstack::base::clientlib':
        version => $version
    }
    contain '::profile::openstack::base::clientlib'
}
