# = Class: role::wdqs
#
# This class sets up Wikidata Query Service
#
class role::wdqs  {
    include standard
    
    # Service-wide definitions
    $deployment_dir = '/srv/deployment/wdqs/wdqs'
    $username       = 'blazegraph'
    $data_dir       = '/var/lib/wdqs'
    $log_dir        = '/var/log/wdqs'

    if $::realm == 'labs' {
        include role::labs::lvm::srv
        $data_dir =  $deployment_dir
        $log_dir  = "$deployment_dir/logs"
    }

    system::role { 'role::wdqs':
        ensure      => 'present',
        description => 'Wikidata Query Service',
    }
    
    # Install service
    class { '::wdqs':
        version     => '0.0.2',
        package_dir => $deployment_dir,
        username    => $username,
        data_dir    => $data_dir,
        log_dir     => $log_dir,
    }

    # Service GUI
    class { '::wdqs::gui':
        package_dir    => $deployment_dir,
        log_aggregator => $wdqs::logstash_host,
        require        => Class['::wdqs'],
    }
    
    # Monitor Blazegraph
    include ::wdqs::monitor::blazegraph
    
    # Monitor Updater
    class { '::wdqs::monitor::updater':
        package_dir    => $deployment_dir,
        username       => $username,
        require        => Class['::wdqs'],
    }
}
