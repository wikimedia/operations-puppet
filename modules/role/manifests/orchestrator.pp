class role::orchestrator {
    system::role { 'orchestrator':
        description => 'Orchestrator server'
    }

    include profile::standard
    include profile::base::firewall
    include profile::orchestrator::web
    include profile::orchestrator::server
    include profile::orchestrator::monitoring
    include profile::mariadb::client
}
