class profile::openstack::base::clientlib(
    $version = hiera('profile::openstack::base::version'),
    ) {

    class {'openstack::clientlib':
        version => $version
    }

    class {'openstack::common':}
}
