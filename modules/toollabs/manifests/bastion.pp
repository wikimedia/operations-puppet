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
class toollabs::bastion($gridmaster) {
  include toollabs,
    ssh::bastion,
    toollabs::exec_environ,
    toollabs::dev_environ

  class { 'gridengine::submit_host':
    gridmaster => $gridmaster,
  }

  # TODO: sshd config
  # TODO: MOTD
  # TODO: local scripts
  # TODO: j* tools
  # TODO: cron setup
}

