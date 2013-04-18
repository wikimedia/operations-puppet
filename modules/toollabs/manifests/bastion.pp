# Class: toollabs::bastion
#
# This role sets up an bastion/dev instance in the Tool Labs model.
#
# Parameters:
#	gridmaster => FQDN of the gridengine master
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::bastion($gridmaster) {
    include toollabs
    include gridengine::submit_host($gridmaster)
    include ssh::bastion
    include toollabs::exec_environ
    include toollabs::dev_environ

# TODO: sshd config
# TODO: MOTD
# TODO: local scripts
# TODO: j* tools
# TODO: cron setup
}

