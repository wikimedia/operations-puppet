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
  $repo  = "/data/project/.system/deb"

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

  file { "/shared":
    ensure => link,
    target => "/data/project/.shared";
  }

  exec { "make_known_hosts":
    command => "/bin/cat $store/hostkey-* >/etc/ssh/ssh_known_hosts~",
    require => File[$store],
  }

  file { "/etc/ssh/ssh_known_hosts":
    ensure => file,
    require => Exec["make_known_hosts"],
    source => "/etc/ssh/ssh_known_hosts~",
    mode => "0444",
    owner => "root",
    group => "root",
  }

  # Tool Labs is enduser-facing, so we want to control the motd
  # properly (most things make no sense for community users: they
  # don't care that packages need updating, or that filesystems
  # will be checked, for instance)

  file { "/etc/update-motd.d":
    ensure => directory,
    mode => "0755",
    owner => "root",
    group => "root",
    force => true,
    recurse => true,
    purge => true,
  }

  file { "/etc/apt/sources.list.d/local.list":
    ensure => file,
    content => "deb arch=amd64 trusted=yes file:$repo/ amd64/\ndeb arch=all trusted=yes file:$repo/ all/\n",
    mode = "0444",
    owner = "root",
    group = "root",
  }

  # Trustworthy enough
  file { "/etc/apt/sources.list.d/mariadb.list":
    ensure => file,
    content => "deb http://ftp.osuosl.org/pub/mariadb/repo/5.5/ubuntu precise main\n",
    mode = "0444",
    owner = "root",
    group = "root",
  }

}

