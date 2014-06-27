#
# This is a nice generic place to make project-specific roles with a sane
# naming scheme.
#

class role::labs::toolsbeta {

    class config {
        include role::labsnfs::client # temporary measure
        $grid_master = 'toolsbeta-master.pmtpa.wmflabs'
    }

    class bastion inherits role::labs::toolsbeta::config {
        system::role { 'role::labs::toolsbeta::bastion': description => 'Tool Labs bastion' }
        class { 'toollabs::bastion':
            gridmaster => $grid_master,
        }
    }

    class execnode inherits role::labs::toolsbeta::config {
        system::role { 'role::labs::toolsbeta::execnode': description => 'Tool Labs execution host' }
        class { 'toollabs::execnode':
            gridmaster => $grid_master,
        }
    }

    class master inherits role::labs::toolsbeta::config {
        system::role { 'role::labs::toolsbeta::master': description => 'Tool Labs gridengine master' }
        class { 'toollabs::master': }
    }

    class shadow inherits role::labs::toolsbeta::config {
        system::role { 'role::labs::toolsbeta::shadow': description => 'Tool Labs gridengine shadow (backup) master' }
        class { 'toollabs::shadow':
            gridmaster => $grid_master,
        }
    }

    class mailrelay inherits role::labs::toolsbeta::config {
        system::role { 'role::labs::toolsbeta::mailrelay': description => 'Tool Labs mail relay' }
        class { 'toollabs::mailrelay':
            maildomain => 'tools-beta.wmflabs.org',
            gridmaster => $grid_master,
        }
    }

    class syslog inherits role::labs::toolsbeta::config {
        system::role { 'role::labs::toolsbeta::syslog': description => 'Central logging server for tools and services' }
        class { 'toollabs::syslog': }
    }

    class redis inherits role::labs::toolsbeta::config {
        system::role { 'role::labs::toolsbeta::redis': description => 'Server that hosts shared Redis instance' }
        class { 'toollabs::redis': }
    }

} # class role::labs::tools
