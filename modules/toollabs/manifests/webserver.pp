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
class toollabs::webserver($gridmaster) {
  include toollabs,
    toollabs::infrastructure,
    toollabs::exec_environ

  class { 'gridengine::submit_host':
    gridmaster => $gridmaster,
  }

  package { [
      'libapache2-mod-suphp',
      ]:
    ensure => present
  }

  # TODO: Apache config
  # TODO: Local scripts
  # TODO: sshd config
}

