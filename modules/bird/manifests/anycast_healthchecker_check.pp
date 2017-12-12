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
define bird::anycast_healthchecker_check(
  Stdlib::IP::Address::V4::Nosubnet $address,
  String $check_cmd,
  Wmflib::Ensure $ensure = 'present',
  ){
  file { "/etc/anycast-healthchecker.d/${title}.conf":
      ensure  => $ensure,
      owner   => 'bird',
      group   => 'bird',
      mode    => '0664',
      content => template('bird/anycast-healthchecker-check.conf.erb'),
      notify  => Service['anycast-healthchecker'],
  }
}
