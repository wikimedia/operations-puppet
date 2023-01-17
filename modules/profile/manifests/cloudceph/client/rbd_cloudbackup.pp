# SPDX-License-Identifier: Apache-2.0
class profile::cloudceph::client::rbd_cloudbackup (
    Boolean                    $enable_v2_messenger       = lookup('profile::cloudceph::client::rbd::enable_v2_messenger'),
    Hash[String,Hash]          $mon_hosts                 = lookup('profile::cloudceph::mon::hosts'),
    Array[Stdlib::IP::Address] $cluster_networks          = lookup('profile::cloudceph::cluster_networks'),
    Array[Stdlib::IP::Address] $public_networks           = lookup('profile::cloudceph::public_networks'),
    Stdlib::Unixpath           $data_dir                  = lookup('profile::cloudceph::data_dir'),
    String[1]                  $fsid                      = lookup('profile::cloudceph::fsid'),
    String[1]                  $ceph_repository_component = lookup('profile::cloudceph::ceph_repository_component'),
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
