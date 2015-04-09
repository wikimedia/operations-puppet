
class role::labs::tools {

    class common {
        $gridmaster = "${::instanceproject}-master.${::site}.wmflabs"

        class { 'gridengine': gridmaster => $gridmaster }
    }

    class bastion inherits role::labs::tools::common {
        include toollabs::bastion

        system::role { 'role::labs::tools::bastion': description => 'Tool Labs bastion' }
    }

    class compute inherits role::labs::tools::common {
        include toollabs::compute

        system::role { 'role::labs::tools::compute': description => 'Tool Labs compute node' }
    }

    class master inherits role::labs::tools::common {
        include toollabs::master

        system::role { 'role::labs::tools::master': description => 'Tool Labs gridengine master' }
    }

    class shadow inherits role::labs::tools::common {
        system::role { 'role::labs::tools::shadow': description => 'Tool Labs gridengine shadow (backup) master' }

        class { 'toollabs::shadow':
            gridmaster => $role::labs::tools::common::gridmaster,
        }
    }

    class services inherits role::labs::tools::common {
        system::role { 'role::labs::tools::services':
            description => 'Tool Labs manifest based services',
        }

        include toollabs::services
    }

    class submit inherits role::labs::tools::common {
        include toollabs::submit

        system::role { 'role::labs::tools::submit': description => 'Tool Labs job submit (cron) host' }
    }

    class proxy inherits role::labs::tools::common {
        include toollabs::proxy

        system::role { 'role::labs::tools::proxy': description => 'Tool labs generic web proxy' }
    }

    class static inherits role::labs::tools::common {
        include toollabs::static

        system::role { 'role::labs::tools::static':
            description => 'Tool Labs static http server',
        }
    }

    class mailrelay inherits role::labs::tools::common {
        system::role { 'role::labs::tools::mailrelay': description => 'Tool Labs mail relay' }

        $maildomain_project = $::instanceproject ? {
            'toolsbeta' => 'tools-beta.wmflabs.org',
            default     => 'tools.wmflabs.org',
        }

        class { 'toollabs::mailrelay':
            maildomain => $maildomain_project
        }
    }

    class redis inherits role::labs::tools::common {
        system::role { 'role::labs::tools::redis': description => 'Server that hosts shared Redis instance' }

        include toollabs::redis
    }

    class redis::slave(
        $master = 'tools-redis',
    ) inherits role::labs::tools::common {

        system::role { 'role::labs::tools::redis::slave':
            description => 'Server that hosts shared Redis instance'
        }
        class { 'toollabs::redis':
            replicate_from => $master,
        }

    }

    class toolwatcher inherits role::labs::tools::common {
        system::role { 'role::labs::tools::toolwatcher':
            description => 'Tool Labs directory structure creator for new tools',
        }
        include toollabs::toolwatcher
    }

    ##
    ## NOTE: Those roles are transitional, and should be removed
    ## from Wikitech entirely in favor of role::labs::tools::compute
    ## followed by explicit toollabs::node::*
    ##

    class execnode inherits role::labs::tools::compute {
        include toollabs::node::compute::general
    }

    class webnode inherits role::labs::tools::compute {
        include toollabs::node::web::lighttpd
    }

    class tomcatnode inherits role::labs::tools::compute {
        include toollabs::node::web::tomcat
    }

} # class role::labs::tools
