class profile::openstack::eqiad1::radosgw(
    String $version = lookup('profile::openstack::eqiad1::version'),
    String $ceph_client_keydata = lookup('profile::openstack::eqiad1::radosgw::client_keydata'),
    ) {

    class { '::profile::openstack::base::radosgw':
        version             => $version,
        ceph_client_keydata => $ceph_client_keydata,
    }
}
