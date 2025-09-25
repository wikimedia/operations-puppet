# SPDX-License-Identifier: Apache-2.0
# @summary Add an IP address to an interface managed by systemd-networkd.
# The define is modeled after interface::ip and its parameters.

define interface::networkd::ip(
  Stdlib::IP::Address $address,
  String $interface = $facts['interface_primary'],
  String $prefixlen = '32',
  String $options = '',
  Wmflib::Ensure $ensure = present,
) {
    # Used to build the final 'ip addr add/del'
    $full_address = "${address}/${prefixlen}"
    $ip_addr_suffix = "${full_address} ${options} dev ${interface}"
    $service_name = "networkd-ip-${title}"

    systemd::service { $service_name:
        ensure  => $ensure,
        content => template('interface/networkd/ip.service.erb'),
        restart => true,
    }
}
