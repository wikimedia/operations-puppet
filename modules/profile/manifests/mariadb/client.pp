# hosts with client utilities to conect to remote servers
# This role provides remote access to mysql server
class profile::mariadb::client {
    class { 'mariadb::packages_client': }

    class { 'mariadb::config':
        config   => 'profile/mariadb/mysqld_config/client.my.cnf.erb',
        socket   => '/run/mysqld/client.sock', # use a non-default one
        ssl      => 'puppet-cert',
        ssl_ca   => '/etc/ssl/certs/Puppet_Internal_CA.pem',
        ssl_cert => '/etc/mysql/ssl/cert.pem',
        ssl_key  => '/etc/mysql/ssl/client.key',
    }
}
