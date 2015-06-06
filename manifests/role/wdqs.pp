# = Class: role::wdqs
#
# This class sets up Wikidata Query Service
#
class role::wdqs  {
    include standard

    # Service-wide definitions
    $username       = 'blazegraph'
    $version        = '0.0.2'
    $log_dir        = '/var/log/wdqs'

    if $::realm == 'labs' {
        include role::labs::lvm::srv
	    $deployment_dir = "/srv/wdqs/blazegraph"
        $data_dir       =  $deployment_dir
    } else {
	    $deployment_dir = '/srv/deployment/wdqs/wdqs'
        $data_dir       = '/var/lib/wdqs'
    }
    
    system::role { 'role::wdqs':
        ensure      => 'present',
        description => 'Wikidata Query Service',
    }

    # Install service
    class { '::wdqs':
        version     => $version,
        package_dir => $deployment_dir,
        username    => $username,
        data_dir    => $data_dir,
        log_dir     => $log_dir,
    }

    # Service GUI
    class { '::wdqs::gui':
        package_dir    => $deployment_dir,
        log_aggregator => hiera('wdqs::logstash_host'),
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
