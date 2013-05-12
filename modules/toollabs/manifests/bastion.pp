# Class: toollabs::bastion
#
# This role sets up an bastion/dev instance in the Tool Labs model.
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
class toollabs::bastion($gridmaster) inherits toollabs {
  include ssh::bastion,
    toollabs::exec_environ,
    toollabs::dev_environ

  class { 'gridengine::submit_host':
    gridmaster => $gridmaster,
  }

  file { "/etc/update-motd.d/40-bastion-banner":
    ensure => file,
    mode => "0755",
    owner => "root",
    group => "root",
    source => "puppet:///modules/toollabs/40-${instanceproject}-bastion-banner",
  }

  file { "$store/submithost-$fqdn":
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0444',
    require => File[$store],
    content => "$ipaddress\n",
  }


  # TODO: sshd config
  # TODO: local scripts
  # TODO: j* tools
  # TODO: cron setup
}

