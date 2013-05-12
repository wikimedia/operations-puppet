# Class: toollabs::execnode
#
# This role sets up an execution node in the Tool Labs model.
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
class toollabs::execnode($gridmaster) inherits toollabs {
  include toollabs::exec_environ

  class { 'gridengine::exec_host':
    gridmaster => $gridmaster,
  }

  file { "/etc/update-motd.d/40-exechost-banner":
    ensure => file,
    mode => "0755",
    owner => "root",
    group => "root",
    source => "puppet:///modules/toollabs/40-${instanceproject}-exechost-banner",
  }

  file { "$store/execnode-$fqdn":
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0444',
    require => File[$store],
    content => "$ipaddress\n",
  }

  # TODO: grid node setup
}

