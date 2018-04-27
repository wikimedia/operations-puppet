class profile::openstack::main::clientlib(
    $version = hiera('profile::openstack::main::version'),
    ) {
    class {'profile::openstack::base::clientlib':
        version => $version
    }
}
