class orchestrator::server {
    apt::package_from_component { 'thirdparty-orchestrator-server':
        component => 'thirdparty/orchestrator',
        packages  => ['orchestrator', 'orchestrator-cli']
    }
}
