class profile::ceph::client::rbd_cloudbackup (
    Boolean             $enable_v2_messenger       = lookup('profile::ceph::client::rbd::enable_v2_messenger'),
    Hash[String,Hash]   $mon_hosts                 = lookup('profile::ceph::mon::hosts'),
    Stdlib::IP::Address $cluster_network           = lookup('profile::ceph::cluster_network'),
    Stdlib::IP::Address $public_network            = lookup('profile::ceph::public_network'),
    Stdlib::Unixpath    $data_dir                  = lookup('profile::ceph::data_dir'),
    String[1]           $fsid                      = lookup('profile::ceph::fsid'),
    String[1]           $ceph_repository_component = lookup('profile::ceph::ceph_repository_component',  { 'default_value' => 'thirdparty/ceph-nautilus-buster' }),
) {
    class { 'ceph::common':
        home_dir                  => $data_dir,
        ceph_repository_component => $ceph_repository_component,
    }

    class { 'ceph::config':
        cluster_network     => $cluster_network,
        enable_libvirt_rbd  => false,
        enable_v2_messenger => $enable_v2_messenger,
        fsid                => $fsid,
        mon_hosts           => $mon_hosts,
        public_network      => $public_network,
    }
}
