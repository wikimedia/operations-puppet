# Class: toollabs::execnode
#
# This role sets up an execution node in the Tool Labs model.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::execnode {
    include toollabs
    include gridengine::exec_host
    include toollabs::exec_environ

# TODO: grid node setup
# TODO: sshd config
}

