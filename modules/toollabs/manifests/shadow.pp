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
    include toollabs
    include gridengine::shadow_master($gridmaster)
    include toollabs::exec_environ

# TODO: grid setup
# TODO: NFS overrides (job queue)
}

