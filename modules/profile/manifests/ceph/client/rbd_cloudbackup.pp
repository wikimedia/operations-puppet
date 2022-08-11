class profile::ceph::client::rbd_cloudbackup (
    Boolean                    $enable_v2_messenger       = lookup('profile::ceph::client::rbd::enable_v2_messenger'),
    Hash[String,Hash]          $mon_hosts                 = lookup('profile::ceph::mon::hosts'),
    Array[Stdlib::IP::Address] $cluster_networks          = lookup('profile::ceph::cluster_networks'),
    Array[Stdlib::IP::Address] $public_networks           = lookup('profile::ceph::public_networks'),
    Stdlib::Unixpath           $data_dir                  = lookup('profile::ceph::data_dir'),
    String[1]                  $fsid                      = lookup('profile::ceph::fsid'),
    String[1]                  $ceph_repository_component = lookup('profile::ceph::ceph_repository_component'),
) {
    class { 'ceph::common':
        home_dir                  => $data_dir,
        ceph_repository_component => $ceph_repository_component,
    }

    class { 'ceph::config':
        cluster_networks    => $cluster_networks,
        enable_libvirt_rbd  => false,
        enable_v2_messenger => $enable_v2_messenger,
        fsid                => $fsid,
        mon_hosts           => $mon_hosts,
        public_networks     => $public_networks,
    }
}
