class profile::orchestrator::server (
    String[1] $db_backend = lookup('profile::orchestrator::server::db_backend', {'default_value' => 'mysql'}),
    String[1] $db_topology_password = lookup('profile::orchestrator::server::db_topology_password'),
    Optional[Stdlib::Host] $db_backend_host = lookup('profile::orchestrator::server::db_backend_host', {'default_value' => undef}),
    Optional[String[1]] $db_backend_password = lookup('profile::orchestrator::server::db_backend_password', {'default_value' => undef}),
) {
    class { 'orchestrator::server':
        db_backend           => $db_backend,
        db_topology_password => $db_topology_password,
        db_backend_host      => $db_backend_host,
        db_backend_password  => $db_backend_password,
    }
    class { 'orchestrator::client': }
}
