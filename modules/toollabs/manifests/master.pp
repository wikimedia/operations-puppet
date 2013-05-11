# Class: toollabs::master
#
# This role sets up a grid master in the Tool Labs model.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::master {
  include toollabs,
    gridengine::master,
    toollabs::infrastructure,
    toollabs::exec_environ

  # TODO: Grid config
  # TODO: Key collection
  # TODO: sshd config
  # TODO: (conditional) shadow config
  # TODO: NFS overrides (job queue)
}

