class orchestrator::client {
    apt::package_from_component { 'thirdparty-orchestrator-client':
        component => 'thirdparty/orchestrator',
        packages  => ['orchestrator-client']
    }
}
