class profile::openstack::labtest::clientlib(
    $version = hiera('profile::openstack::labtest::version'),
    ) {

    require ::profile::openstack::labtest::cloudrepo
    class {'::profile::openstack::base::clientlib':
        version => $version
    }
    contain '::profile::openstack::base::clientlib'
}
