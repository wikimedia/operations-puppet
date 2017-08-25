class profile::openstack::base::clientlib(
    $version = hiera('profile::openstack::base::version'),
    ) {

    class {'openstack2::clientlib':
        version => $version
    }

    class {'openstack2::common':}
}
