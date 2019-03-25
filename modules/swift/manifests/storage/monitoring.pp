class swift::storage::monitoring {
    include ::nrpe

    # T80722. Moved here from nrpe_local.cfg
    swift::storage::monitor_swift_daemon { [
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
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Swift',
    }
}
