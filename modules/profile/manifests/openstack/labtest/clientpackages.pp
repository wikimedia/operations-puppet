class profile::openstack::labtest::clientpackages(
    String $version = hiera('profile::openstack::labtest::version'),
) {
    class { '::profile::openstack::base::clientpackages':
        version => $version,
    }
    contain '::profile::openstack::base::clientpackages'
}
