# db master failover with a proxy
class role::mariadb::proxy::master {
    include profile::base::production
    include profile::mariadb::proxy
    include profile::mariadb::proxy::master
}

