# Class: toollabs::shadow
#
# This role sets up a grid shadow master in the Tool Labs model.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::shadow {
    include toollabs
    include gridengine::shadow_master
    include toollabs::exec_environ

# TODO: grid setup
# TODO: NFS overrides (job queue)
}

