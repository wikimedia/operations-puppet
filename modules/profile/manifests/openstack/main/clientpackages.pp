class profile::openstack::main::clientpackages(
    String $version = hiera('profile::openstack::main::version'),
) {
    class { '::profile::openstack::base::clientpackages':
        version => $version,
    }
    contain '::profile::openstack::base::clientpackages'
}
