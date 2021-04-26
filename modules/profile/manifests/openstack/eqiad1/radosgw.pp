class profile::openstack::eqiad1::radosgw(
    String $version = lookup('profile::openstack::eqiad1::version'),
    ) {

    class { '::profile::openstack::base::radosgw':
        version             => $version,
    }
}
