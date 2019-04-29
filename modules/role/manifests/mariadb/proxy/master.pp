# db master failover with a proxy
class role::mariadb::proxy::master {
    include ::profile::standard

    system::role { 'mariadb::proxy::master':
        description => 'DB Proxy with failover',
    }

    include ::profile::mariadb::proxy
    include ::profile::mariadb::proxy::master
}

