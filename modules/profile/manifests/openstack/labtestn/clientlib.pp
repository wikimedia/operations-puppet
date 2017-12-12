class profile::openstack::labtestn::clientlib(
    $version = hiera('profile::openstack::labtestn::version'),
    ) {

    require ::profile::openstack::labtestn::cloudrepo
    class {'profile::openstack::base::clientlib':
        version => $version
    }
    contain 'profile::openstack::base::clientlib'
}
