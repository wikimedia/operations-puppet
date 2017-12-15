# db master failover with a proxy
class role::mariadb::proxy::master {

    include role::mariadb::ferm
    include ::profile::mariadb::proxy
    include ::profile::mariadb::proxy::master
}

