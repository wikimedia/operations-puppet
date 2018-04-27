class profile::openstack::main::clientlib(
    $version = hiera('profile::openstack::main::version'),
    ) {

    require ::profile::openstack::main::clientrepo

    class {'profile::openstack::base::clientlib':
        version => $version
    }
}
