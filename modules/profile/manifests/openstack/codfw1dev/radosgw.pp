class profile::openstack::codfw1dev::radosgw(
    String $version = lookup('profile::openstack::codfw1dev::version'),
    ) {

    class { '::profile::openstack::base::radosgw':
        version             => $version,
    }
}
