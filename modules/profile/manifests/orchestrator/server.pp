class profile::orchestrator::server {
    class { 'orchestrator::server': }
    class { 'orchestrator::client': }
}
