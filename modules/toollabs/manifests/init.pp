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

  $store = "/data/project/.system/store"
  $repo  = "/data/project/.system/deb"

  #
  # The $store is an incredibly horrid workaround the fact that we cannot
  # use exported resources in our puppet setup: individual instances store
  # information in a shared filesystem that are collected locally into
  # files to finish up the configuration.
  #
  # Case in point here: SSH host keys distributed around the project for
  # known_hosts and HBA of the execution nodes.
  #

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
    content => "[$fqdn]:*,[$ipaddress]:* ssh-rsa $sshrsakey\n$fqdn ssh-rsa $sshrsakey\n",
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

  # this is a link to shared folder
  file { "/shared":
    ensure => link,
    target => "/data/project/.shared";
  }

  # this file contains the motd tips and also the admin motd script
  # in fact it just check if the shared script exist and if so
  # it executes it
  file { "/etc/profile.d/tips.sh":
    ensure => file,
    source => "puppet:///modules/toollabs/profile-tool-labs.sh",
    mode => "0555",
    owner => "root",
    group => "root",
  }

  file { "/root/.bashrc":
    ensure => file,
    source => "puppet:///modules/toollabs/rootrc",
    mode => "0750",
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

  # We keep a project-locat apt repo where we stuff packages we build
  # that are intended to be local to the project.  By keeping it on the
  # shared storage, we have no need to set up a server to use it.

  file { "/etc/apt/sources.list.d/local.list":
    ensure => file,
    content => "deb [ arch=amd64 trusted=yes ] file:$repo/ amd64/\ndeb [ arch=all trusted=yes ] file:$repo/ all/\n",
    mode => "0444",
    owner => "root",
    group => "root",
  }

  # Trustworthy enough
  file { "/etc/apt/sources.list.d/mariadb.list":
    ensure => file,
    content => "deb http://ftp.osuosl.org/pub/mariadb/repo/5.5/ubuntu precise main\n",
    mode => "0444",
    owner => "root",
    group => "root",
  }

  File <| title == '/etc/exim4/exim4.conf' |> {
    content => undef,
    source => [ "$store/mail-relay", "puppet:///modules/toollabs/exim4-norelay.conf" ],
    notify => Service['exim4'],
  }

  file { "/var/mail":
    ensure => link,
    force => true,
    target => "$store/mail",
  }

}

