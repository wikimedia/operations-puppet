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
class toollabs::execnode($gridmaster) {
  include toollabs,
    toollabs::exec_environ

  class { 'gridengine::exec_host':
    gridmaster => $gridmaster,
  }

  # TODO: grid node setup
  # TODO: sshd config
}

