class profile::ceph::client::rbd_cloudcontrol(
    Boolean             $enable_v2_messenger = lookup('profile::ceph::client::rbd::enable_v2_messenger'),
    Hash[String,Hash]   $mon_hosts           = lookup('profile::ceph::mon::hosts'),
    Stdlib::IP::Address $cluster_network     = lookup('profile::ceph::cluster_network'),
    Stdlib::IP::Address $public_network      = lookup('profile::ceph::public_network'),
    Stdlib::Unixpath    $data_dir            = lookup('profile::ceph::data_dir'),
    String              $fsid                = lookup('profile::ceph::fsid'),
    String              $ceph_repository_component  = lookup('profile::ceph::ceph_repository_component',  { 'default_value' => 'thirdparty/ceph-nautilus-buster' }),
    Stdlib::Port        $radosgw_port        = lookup('profile::ceph::client::rbd::radosgw_port'),
    String              $keystone_internal_uri = lookup('profile::ceph::client::rbd::keystone_internal_uri'),
    String              $radosgw_service_user = lookup('profile::ceph::client::rbd::radosgw_service_user'),
    String              $radosgw_service_user_project = lookup('profile::ceph::client::rbd::radosgw_service_user_project'),
    String              $radosgw_service_user_pass = lookup('profile::ceph::client::rbd::radosgw_service_user_pass'),
) {

    class { 'ceph::common':
        home_dir                  => $data_dir,
        ceph_repository_component => $ceph_repository_component,
    }

    class { 'ceph::config':
        cluster_network              => $cluster_network,
        enable_libvirt_rbd           => false,
        enable_v2_messenger          => $enable_v2_messenger,
        fsid                         => $fsid,
        mon_hosts                    => $mon_hosts,
        public_network               => $public_network,
        radosgw_port                 => $radosgw_port,
        keystone_internal_uri        => $keystone_internal_uri,
        radosgw_service_user         => $radosgw_service_user,
        radosgw_service_user_project => $radosgw_service_user_project,
        radosgw_service_user_pass    => $radosgw_service_user_pass,
    }
}
