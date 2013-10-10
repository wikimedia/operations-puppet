# Class: toollabs::webnode
#
# This role sets up an web node in the Tool Labs model.
#
# Parameters:
#       gridmaster => FQDN of the gridengine master
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::webnode($gridmaster) inherits toollabs {
  include toollabs::exec_environ
  include toollabs::infrastructure

  class { 'gridengine::exec_host':
    gridmaster => $gridmaster,
  }

  file { "$store/execnode-$fqdn":
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0444',
    require => File[$store],
    content => "$ipaddress\n",
  }

  # Execution hosts have funky access requirements; they need to be ssh-able
  # by service accounts, and they need to use host-based authentication.

  # We override /etc/ssh/shosts.equiv and /etc/security/access.conf
  # accordingly from information collected from the project store.

  file { "/usr/local/sbin/project-make-shosts":
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0755',
    source => "puppet:///modules/toollabs/project-make-shosts",
  }

  exec { "make-shosts":
    command => "/usr/local/sbin/project-make-shosts >/etc/ssh/shosts.equiv~",
    require => File['/usr/local/sbin/project-make-shosts', $store],
  }

  file { "/etc/ssh/shosts.equiv":
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0444',
    source => "/etc/ssh/shosts.equiv~",
    require => Exec['make-shosts'],
  }

  file { "/usr/local/sbin/project-make-access":
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0755',
    source => "puppet:///modules/toollabs/project-make-access",
  }

  exec { "make-access":
    command => "/usr/local/sbin/project-make-access >/etc/security/access.conf~",
    require => File['/usr/local/sbin/project-make-access', $store],
  }

  File <| title == '/etc/security/access.conf' |> {
    content => undef,
    source => "/etc/security/access.conf~",
    require => Exec['make-access'],
  }

  package { 'lighttpd': ensure => present }
  package { 'apache2.2-common': ensure => absent }

  file { "/usr/local/sbin/tool-lighttpd":
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0755',
    source => "puppet:///modules/toollabs/tool-lighttpd",
  }

}

