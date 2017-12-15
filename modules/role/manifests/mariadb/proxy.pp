# generic config for a database proxy using haproxy
class role::mariadb::proxy {
    include ::standard

    system::role { 'mariadb::proxy':
        description => 'DB Proxy',
    }

    include ::profile::haproxy
    include ::profile::mariadb::client
}
