class profile::openstack::eqiad1::clientlib(
    $version = hiera('profile::openstack::eqiad1::version'),
    ) {
    class {'profile::openstack::base::clientlib':
        version => $version
    }
    contain '::profile::openstack::base::clientlib'
}
