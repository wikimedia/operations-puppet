# SPDX-License-Identifier: Apache-2.0
# == Class: bird::anycast_healthchecker_check
#
# Add service health check for anycast_healthchecker
#
# === Parameters
#
# [*address*]
#  The VIP being monitored with this check
#
# [*check_cmd*]
#  The full health check command for this VIP
#
# [*ensure*]
#  Standard file ensure. Default: present
#
# [*check_fail*]
#  Number of failures after which to consider the service down. Default: 1
#
# [*do_ipv6*]
#  Whether to enable IPv6 support. default: false.
#
# [*address_ipv6*]
#  The IPv6 VIP being monitored with this check. default: undef.
#
# [*check_cmd_ipv6*]
#  The full health check command for the IPv6 VIP. default: undef.

define bird::anycast_healthchecker_check(
  Stdlib::IP::Address::V4::Nosubnet $address,
  String $check_cmd,
  Wmflib::Ensure $ensure = 'present',
  Integer $check_fail = 1,
  Boolean $do_ipv6 = false,
  Optional[Stdlib::IP::Address::V6::Nosubnet] $address_ipv6 = undef,
  Optional[String] $check_cmd_ipv6 = undef,
  ){

  if $do_ipv6 {
    $title_ipv6 = "${title}.ipv6"
  }

  file { "/etc/anycast-healthchecker.d/${title}.conf":
      ensure  => $ensure,
      owner   => 'bird',
      group   => 'bird',
      mode    => '0664',
      content => template('bird/anycast-healthchecker-check.conf.erb'),
      notify  => Service['anycast-healthchecker'],
  }
}
