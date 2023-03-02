# SPDX-License-Identifier: Apache-2.0
# Class: profile::ceph::mon
#
# This profile configures hosts with the Ceph mon daemon
class profile::ceph::mon (
  Stdlib::Unixpath           $data_dir                  = lookup('profile::ceph::data_dir', { default_value => '/var/lib/ceph' }),
  String                     $fsid                      = lookup('profile::ceph::fsid'),
  Ceph::Auth::Conf           $ceph_auth_conf            = lookup('profile::ceph::auth::load_all::configuration'),
) {
  require profile::ceph::auth::load_all

  require profile::ceph::server::firewall

  require profile::ceph::core

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
