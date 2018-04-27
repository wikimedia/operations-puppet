class profile::openstack::labtest::clientlib(
    $version = hiera('profile::openstack::labtest::version'),
    ) {
    class {'::profile::openstack::base::clientlib':
        version => $version
    }
    contain '::profile::openstack::base::clientlib'
}
