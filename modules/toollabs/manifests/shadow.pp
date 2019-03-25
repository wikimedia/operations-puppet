# This role sets up a grid shadow master in the Toolforge model.
#
# [*gridmaster*]
#   FQDN of the gridengine master

class toollabs::shadow($gridmaster) inherits toollabs {

    include ::toollabs::infrastructure

    class { '::gridengine::shadow_master':
        gridmaster => $gridmaster,
        sgeroot    => "${toollabs::sysdir}/gridengine",
    }
}
