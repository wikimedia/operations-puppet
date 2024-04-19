# SPDX-License-Identifier: Apache-2.0
# @summary adds an interface to an existing bridge
define openvswitch::bridge::member (
  String[1] $bridge,
  String[1] $interface = $title,
) {
  exec { "bridge-create-${bridge}-${interface}":
    command => "/usr/bin/ovs-vsctl add-port ${bridge} ${interface}",
    unless  => "/usr/bin/ovs-vsctl port-to-br ${interface}",
    require => Openvswitch::Bridge[$bridge],
  }
}
