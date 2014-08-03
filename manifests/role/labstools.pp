
class role::labs::tools {

    class config {
        if $::site != 'eqiad' {
            include role::labsnfs::client # temporary measure
        }

        $grid_master = $::site? {
            'eqiad' => "${::instanceproject}-master.eqiad.wmflabs",
            default => "${::instanceproject}-master.pmtpa.wmflabs",
        }
    }

    class bastion inherits role::labs::tools::config {
        system::role { 'role::labs::tools::bastion': description => 'Tool Labs bastion' }
        class { 'toollabs::bastion':
            gridmaster => $grid_master,
        }
    }

    class execnode inherits role::labs::tools::config {
        system::role { 'role::labs::tools::execnode': description => 'Tool Labs execution host' }
        class { 'toollabs::execnode':
            gridmaster => $grid_master,
        }
    }

    class webnode inherits role::labs::tools::config {
        system::role { 'role::labs::tools::webnode': description => 'Tool Labs clustered web host' }
        class { 'toollabs::webnode':
            gridmaster => $grid_master,
            type => 'lighttpd',
        }
    }

    class tomcatnode inherits role::labs::tools::config {
        system::role { 'role::labs::tools::tomcatnode': description => 'Tool Labs clustered tomcat host' }
        class { 'toollabs::webnode':
            gridmaster => $grid_master,
            type => 'tomcat',
        }
    }

    class master inherits role::labs::tools::config {
        system::role { 'role::labs::tools::master': description => 'Tool Labs gridengine master' }
        class { 'toollabs::master': }
    }

    class shadow inherits role::labs::tools::config {
        system::role { 'role::labs::tools::shadow': description => 'Tool Labs gridengine shadow (backup) master' }
        class { 'toollabs::shadow':
            gridmaster => $grid_master,
        }
    }

    class submit inherits role::labs::tools::config {
        system::role { 'role::labs::tools::submit': description => 'Tool Labs job submit (cron) host' }
        class { 'toollabs::submit':
            gridmaster => $grid_master,
        }
    }

    class proxy inherits role::labs::tools::config {
        system::role { 'role::labs::tools::proxy': description => 'Tool labs generic web proxy' }
        include toollabs::proxy
    }

    class mailrelay inherits role::labs::tools::config {
        system::role { 'role::labs::tools::mailrelay': description => 'Tool Labs mail relay' }
        class { 'toollabs::mailrelay':
            maildomain => $::instanceproject ? {
                'toolsbeta' => 'tools-beta.wmflabs.org',
                default     => 'tools.wmflabs.org',
            },
            gridmaster => $grid_master,
        }
    }

    class redis inherits role::labs::tools::config {
        system::role { 'role::labs::tools::redis': description => 'Server that hosts shared Redis instance' }
        class { 'toollabs::redis':
            maxmemory => $::redis_maxmemory
        }
    }

    class mongo inherits role::labs::tools::config {
        system::role { 'role::labs::tools::mongo':
            description => 'Server that hosts shared MongoDB instance'
        }

        class { 'toollabs::mongo::master':}
    }
} # class role::labs::tools
