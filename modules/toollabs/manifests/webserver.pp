# Class: toollabs::webserver
#
# This role sets up a webserver in the Tool Labs model.
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
class toollabs::webserver($gridmaster) inherits toollabs {
  include toollabs::infrastructure,
    toollabs::exec_environ

  class { 'gridengine::submit_host':
    gridmaster => $gridmaster,
  }

  package { [
      'libapache2-mod-suphp',
      ]:
    ensure => present
  }

  file { "$store/submithost-$fqdn":
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0444',
    require => File[$store],
    content => "$ipaddress\n",
  }

  # TODO: Apache config
  # TODO: Local scripts
  # TODO: sshd config
}

