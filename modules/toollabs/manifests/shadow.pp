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
class toollabs::shadow($gridmaster) inherits toollabs {
    include toollabs::infrastructure

    class { 'gridengine::shadow_master':
        gridmaster => $gridmaster,
        sgeroot    => "${toollabs::sysdir}/gridengine",
    }
}
