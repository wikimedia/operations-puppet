class profile::openstack::main::clientlib(
    $version = hiera('profile::openstack::main::version'),
    ) {

    require ::profile::openstack::main::cloudrepo
    class {'profile::openstack::base::clientlib':
        version => $version
    }
}
