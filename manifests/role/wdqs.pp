# = Class: role::wdqs
#
# This class sets up Wikidata Query Service
#
class role::wdqs{
    include standard
    include role::labs::lvm::srv

    system::role { 'role::wdqs':
        ensure      => 'present',
        description => 'WDQS server',
    }

    # Install service
    class { '::wdqs':
        version => '0.0.2',
        package_dir => '/srv/wdqs',
        username    => 'blazegraph',
    }

    # Service GUI
    class { '::wdqs::gui':
        package_dir    => '/srv/wdqs/blazegraph',
        log_aggregator => 'deployment-logstash1.eqiad.wmflabs:10514',
        require        => Class['::wdqs'],
    }
    
    # Monitor Blazegraph
    include ::wdqs::monitor::blazegraph
    # Monitor Updater
    class { '::wdqs::monitor::updater':
        package_dir    => '/srv/wdqs/blazegraph',
        username    => 'blazegraph',
        require        => Class['::wdqs'],
    }
}
