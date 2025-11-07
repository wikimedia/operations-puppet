# SPDX-License-Identifier: Apache-2.0
# @summary manages the MTU setting on a specific interface
define interface::mtu (
  Integer   $mtu,
  String[1] $interface = $title,
) {
  interface::setting { "mtu-${title}":
    interface => $interface,
    setting   => 'mtu',
    value     => String($mtu),
    notify    => Exec["mtu-${title}"],
  }
  exec { "mtu-${title}":
    command     => "/usr/sbin/ip link set mtu ${mtu} ${interface}",
    refreshonly => true,
    onlyif      => "/usr/sbin/ifquery --state ${interface}",
  }
}
