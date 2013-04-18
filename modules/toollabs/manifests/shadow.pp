# Class: toollabs::shadow
#
# This role sets up a grid shadow master in the Tool Labs model.
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
class toollabs::shadow($gridmaster) {
  include toollabs,
    toollabs::exec_environ

  class { 'gridengine::shadow_master':
    gridmaster => $gridmaster,
  }

  # TODO: grid setup
  # TODO: NFS overrides (job queue)
}

