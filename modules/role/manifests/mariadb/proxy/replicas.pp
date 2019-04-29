# db replicas load balancing with a proxy
class role::mariadb::proxy::replicas {
    include ::profile::standard

    system::role { 'mariadb::proxy':
        description => 'DB Proxy with load balancing',
    }
    include ::profile::mariadb::proxy
    include ::profile::mariadb::proxy::replicas
}
