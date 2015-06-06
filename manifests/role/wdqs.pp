# = Class: role::wdqs
#
# This class sets up Wikidata Query Service
#
class role::wdqs{

    include standard
#   include role::labs::lvm::srv

    system::role { 'role::wdqs':
        ensure      => 'present',
        description => 'WDQS server',
    }

    # Install service
    class { '::wdqs':
        package_dir       => '/srv',
        username          => 'blazegraph',
    }

    # Service GUI
    class { '::wdqs::gui':
        package_dir       => '/srv/blazegraph',
        log_aggregator => '10.68.16.147:10514',
        require => Class['::wdqs']
    }
}
