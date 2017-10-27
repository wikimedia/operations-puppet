# === Class role::cumin::master
#
# This class setup a Cumin master server
#
class role::cumin::master {
    include ::profile::cumin::master

    system::role { 'cumin::master':
        description => 'Install Cumin and configure the host to be a Cumin master',
    }
}
