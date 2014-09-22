class swift_new::storage::monitoring {
    define monitor_swift_daemon {
        # nrpe::monitor_service will create
        # nrpe::check command definition and a
        # monitor_service definition which exports to nagios
        nrpe::monitor_service { $title:
            description  => $title,
            nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array='^/usr/bin/python /usr/bin/${title}'",
        }
    }
    include nrpe

    # RT-2593. Moved here from nrpe_local.cfg
    monitor_swift_daemon { [
        'swift-account-auditor',
        'swift-account-reaper',
        'swift-account-replicator',
        'swift-account-server',
        'swift-container-auditor',
        'swift-container-replicator',
        'swift-container-server',
        'swift-container-updater',
        'swift-object-auditor',
        'swift-object-replicator',
        'swift-object-server',
        'swift-object-updater',
    ]: }

    nrpe::monitor_service { 'load_average':
        description  => 'very high load average likely xfs',
        nrpe_command => '/usr/lib/nagios/plugins/check_load -w 80,80,80 -c 200,100,100',
    }
}
