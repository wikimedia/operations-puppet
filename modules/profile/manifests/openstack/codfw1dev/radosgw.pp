class profile::openstack::codfw1dev::radosgw(
    String $version = lookup('profile::openstack::codfw1dev::version'),
    String $ceph_client_keydata = lookup('profile::openstack::codfw1dev::radosgw::client_keydata'),
    ) {

    class { '::profile::openstack::base::radosgw':
        version             => $version,
        ceph_client_keydata => $ceph_client_keydata,
    }
}
