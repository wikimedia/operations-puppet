# generic config for a database proxy using haproxy
class role::mariadb::proxy {
    include ::standard
    include ::profile::base::firewall

    system::role { 'mariadb::proxy':
        description => 'DB Proxy',
    }

    include ::profile::mariadb::proxy
    include ::profile::mariadb::client
}
