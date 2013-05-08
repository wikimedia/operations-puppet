# Class: toollabs
#
# This is a "sub" role included by the actual tool labs roles and would
# normally not be included directly in node definitions.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs {
  # TODO: autofs overrides
  # TODO: PAM config

  $store = "/data/project/.system/store"

  file { $store:
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '0755',
    require => Service["autofs"],
  }

  file { "$store/hostkey-$fqdn":
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0444',
    require => File[$store],
    content => "[$fqdn]:* ssh-dss $sshdsakey\n[$ipaddress]:* ssh-dss $sshdsakey\n",
  }

  exec { "make_known_hosts":
    command => "/bin/cat /data/project/.system/store/hostkey-* >/etc/ssh/ssh_known_hosts~",
    requires => File[$store],
  }

  file { "/etc/ssh/ssh_known_hosts":
    ensure => file,
    require => Exec["make_known_hosts"],
    source => "/etc/ssh/ssh_known_hosts~",
    mode => "0444",
    owner => "root",
    group => "root",
  }
}

