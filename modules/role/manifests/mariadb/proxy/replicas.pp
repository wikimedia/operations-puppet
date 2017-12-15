# db replicas load balancing with a proxy
class role::mariadb::proxy::replicas {

    include role::mariadb::ferm
    include ::profile::mariadb::proxy
    include ::profile::mariadb::proxy::replicas
}
