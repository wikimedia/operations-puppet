class profile::orchestrator::server (
    String[1] $db_backend_password = lookup('profile::orchestrator::server::db_backend_password'),
) {
    class { 'orchestrator::server':
        db_backend_host     => 'db2093.codfw.wmnet',
        db_backend_password => $db_backend_password,
    }
    class { 'orchestrator::client': }
}
