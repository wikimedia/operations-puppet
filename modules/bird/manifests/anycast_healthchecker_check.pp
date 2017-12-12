# == Class: bird::anycast_healthchecker_check
#
# Add service health check for anycast_healthchecker
#
# === Parameters
#
# [*ensure*]
#  Standard file ensure
#
# [*anycast_vip*]
#  The VIP being monitored with this check
#
# [*check_cmd*]
#  The full health check command for this VIP
#
# [*check_name*]
#  The name of the check
#
class bird::anycast_healthchecker_check(
  $ensure,
  $anycast_vip,
  $check_cmd,
  $check_name,
  ){

  file { "/etc/anycast-healthchecker.d/${check_name}.conf":
      ensure  => $ensure,
      owner   => 'bird',
      group   => 'bird',
      mode    => '0664',
      content => template('bird/anycast-healthchecker-check.conf.erb'),
      notify  => Service['anycast-healthchecker'],
  }
}
