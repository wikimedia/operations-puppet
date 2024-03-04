# @summary manages an openvswitch switch
# SPDX-License-Identifier: Apache-2.0
class openvswitch () {
  ensure_packages(['openvswitch-switch'])

  service { 'openvswitch-switch':
    ensure => running,
    enable => true,
  }
}
