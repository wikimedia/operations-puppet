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
    include toollabs
    include gridengine::exec_host($gridmaster)
    include toollabs::exec_environ

# TODO: grid node setup
# TODO: sshd config
}

