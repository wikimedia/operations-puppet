# SPDX-License-Identifier: Apache-2.0
# Class: profile::ceph::mon
#
# This profile configures hosts with the Ceph mds daemon
class profile::ceph::mds (
  Stdlib::Unixpath           $data_dir                  = lookup('profile::ceph::data_dir', { default_value => '/var/lib/ceph' }),
  String                     $fsid                      = lookup('profile::ceph::fsid'),
  Ceph::Auth::Conf           $ceph_auth_conf            = lookup('profile::ceph::auth::load_all::configuration'),
) {
  require profile::ceph::auth::load_all

  require profile::ceph::server::firewall

  require profile::ceph::core

  Class['ceph::mds'] -> Class['ceph::mgr']

  # Separate var to work around puppet-lint parsing bug,
  # https://github.com/puppetlabs/puppet-lint/issues/267
  $mds = "mds.${facts['networking']['hostname']}"
  class { 'ceph::mds':
      data_dir => $data_dir,
      mds_auth => $ceph_auth_conf[$mds],
  }
}
