# @summary manages an openvswitch switch
# SPDX-License-Identifier: Apache-2.0
class openvswitch () {
  package {'openvswitch-switch':
    ensure => installed,
  }

  service { 'openvswitch-switch':
    ensure => running,
    enable => true,
  }
}
