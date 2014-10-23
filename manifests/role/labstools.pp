
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
        include toollabs::shadow

        system::role { 'role::labs::tools::shadow': description => 'Tool Labs gridengine shadow (backup) master' }
    }

    class submit inherits role::labs::tools::common {
        include toollabs::submit

        system::role { 'role::labs::tools::submit': description => 'Tool Labs job submit (cron) host' }
    }

    class proxy inherits role::labs::tools::common {
        include toollabs::proxy

        system::role { 'role::labs::tools::proxy': description => 'Tool labs generic web proxy' }
    }

    class mailrelay inherits role::labs::tools::common {
        system::role { 'role::labs::tools::mailrelay': description => 'Tool Labs mail relay' }

        class { 'toollabs::mailrelay':
            maildomain => $::instanceproject ? {
                'toolsbeta' => 'tools-beta.wmflabs.org',
                default     => 'tools.wmflabs.org',
            },
        }
    }

    class redis inherits role::labs::tools::common {
        system::role { 'role::labs::tools::redis': description => 'Server that hosts shared Redis instance' }

        class { 'toollabs::redis':
            maxmemory => $::redis_maxmemory
        }
    }

    class mongo inherits role::labs::tools::common {
        include toollabs::mongo::master

        system::role { 'role::labs::tools::mongo':
            description => 'Server that hosts shared MongoDB instance'
        }
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
