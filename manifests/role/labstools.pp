
class role::labs::tools {

    class common {
        include ::gridengine
    }

    class bastion {
        include toollabs::bastion

        system::role { 'role::labs::tools::bastion': description => 'Tool Labs bastion' }
    }

    class compute {
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
            gridmaster => hiera('gridengine::gridmaster'),
        }
    }

    class services(
        $active_host = 'tools-services-01.eqiad.wmflabs',
    ) {
        system::role { 'role::labs::tools::services':
            description => 'Tool Labs manifest based services',
        }

        class { 'toollabs::services':
            active => ($::fqdn == $active_host),
        }

        class { 'toollabs::bigbrother':
            active => ($::fqdn == $active_host),
        }

        class { 'toollabs::updatetools':
            active => ($::fqdn == $active_host),
        }
    }

    class checker {
        include toollabs::checker

        system::role { 'role::labs::tools::checker':
            description => 'Exposes end points for external monitoring of internal systems',
        }
    }

    class cronrunner {
        include ::toollabs::cronrunner

        system::role { 'role::labs::tools::cronrunner':
            description => 'Tool Labs cron starter host',
        }
    }

    class submit {
        include ::toollabs::submit

        system::role { 'role::labs::tools::submit':
            description => 'Tool Labs job submit (cron) host',
        }
    }

    class proxy {
        include toollabs::proxy
        include role::toollabs::k8s::webproxy

        system::role { 'role::labs::tools::proxy': description => 'Tool labs generic web proxy' }
    }

    class static {
        include toollabs::static

        system::role { 'role::labs::tools::static':
            description => 'Tool Labs static http server',
        }
    }

    class mailrelay {
        system::role { 'role::labs::tools::mailrelay': description => 'Tool Labs mail relay' }

        include toollabs::mailrelay
    }

    class redis {
        system::role {
            'role::labs::tools::redis':
            description => 'Server that hosts shared Redis instance'
        }

        include toollabs::redis
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
} # class role::labs::tools
