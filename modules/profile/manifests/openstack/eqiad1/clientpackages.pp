class profile::openstack::eqiad1::clientpackages(
    String $version = lookup('profile::openstack::eqiad1::version'),
) {
    class { '::profile::openstack::base::clientpackages':
        version => $version,
    }
    contain '::profile::openstack::base::clientpackages'
}
