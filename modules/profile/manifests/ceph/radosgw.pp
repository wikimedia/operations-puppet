# SPDX-License-Identifier: Apache-2.0
# Class: profile::ceph::radosgw
#
# This profile configures hosts with the Ceph RADOS Gateway daemon
class profile::ceph::radosgw (
  Stdlib::Port $radosgw_port    = lookup('profile::ceph::radosgw::port'),
  String       $firewall_srange = lookup('profile::ceph::radosgw::firewall_srange'),
) {
  require profile::ceph::auth::load_all

  require profile::ceph::core

  class { 'ceph::radosgw': }

  firewall::service { 'radosgw-https':
        proto  => 'tcp',
        port   => 443,
        srange => $firewall_srange,
    }
}
