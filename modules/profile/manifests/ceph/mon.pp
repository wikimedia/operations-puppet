# SPDX-License-Identifier: Apache-2.0
# Class: profile::ceph::mon
#
# This profile configures hosts with the Ceph mon daemon
class profile::ceph::mon (
  Hash[String,Hash]          $mon_hosts                 = lookup('profile::ceph::mon::hosts'),
  Hash[String,Hash]          $osd_hosts                 = lookup('profile::ceph::osd::hosts'),
  Array[Stdlib::IP::Address] $public_networks           = lookup('profile::ceph::public_networks'),
  Array[Stdlib::IP::Address] $cluster_networks          = lookup('profile::ceph::cluster_networks', { default_value => [] }),
  Stdlib::Unixpath           $data_dir                  = lookup('profile::ceph::data_dir', { default_value => '/var/lib/ceph' }),
  String                     $fsid                      = lookup('profile::ceph::fsid'),
  String                     $ceph_repository_component = lookup('profile::ceph::ceph_repository_component'),
  Ceph::Auth::Conf           $ceph_auth_conf            = lookup('profile::ceph::auth::load_all::configuration'),
) {
  require profile::ceph::auth::load_all

  require profile::ceph::server::firewall

  class { 'ceph::common':
    home_dir                  => $data_dir,
    ceph_repository_component => $ceph_repository_component,
  }

  class { 'ceph::config':
    cluster_networks    => $cluster_networks,
    enable_libvirt_rbd  => false,
    enable_v2_messenger => true,
    fsid                => $fsid,
    mon_hosts           => $mon_hosts,
    osd_hosts           => $osd_hosts,
    public_networks     => $public_networks,
  }

  class { 'ceph::mon':
    data_dir   => $data_dir,
    fsid       => $fsid,
    admin_auth => $ceph_auth_conf['admin'],
    mon_auth   => $ceph_auth_conf["mon.${::hostname}"],
  }

  Class['ceph::mon'] -> Class['ceph::mgr']

  class { 'ceph::mgr':
      data_dir => $data_dir,
      mgr_auth => $ceph_auth_conf["mgr.${::hostname}"],
  }
}
