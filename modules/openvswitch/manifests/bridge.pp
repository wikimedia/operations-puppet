# SPDX-License-Identifier: Apache-2.0
# @summary manages an openvswitch bridge
define openvswitch::bridge () {
  exec { "bridge-create-${title}":
    command => "/usr/bin/ovs-vsctl add-br ${title}",
    unless  => "/usr/bin/ovs-vsctl br-exists ${title}",
    require => Service['openvswitch-switch'],
  }
}
