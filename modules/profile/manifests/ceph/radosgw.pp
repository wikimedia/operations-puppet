# SPDX-License-Identifier: Apache-2.0
# Class: profile::ceph::radosgw
#
# This profile configures hosts with the Ceph RADOS Gateway daemon
class profile::ceph::radosgw {
  require profile::ceph::auth::load_all

  require profile::ceph::core

  class { 'ceph::radosgw': }
}
