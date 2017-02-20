# hosts with client utilities to conect to remote servers
# This role provides remote access to mysql server
# **DO NOT ADD** to non-dedicated hosts**
class role::mariadb::client {

    # prevent accidental addition on a db server or a non-dedicated client
    if !($::fqdn in ['neodymium.eqiad.wmnet', 'sarin.codfw.wmnet']) {
        fail('role::mariadb::client should only be used on root-owned, \
             dedicated servers.')
    }

    include mariadb::packages_client
    include passwords::misc::scripts

    class { 'mariadb::config':
        config => 'role/mariadb/mysqld_config/client.my.cnf.erb',
        ssl    => 'puppet-cert',
    }

    $password = $passwords::misc::scripts::mysql_root_pass
    $labsdb_password = $passwords::misc::scripts::mysql_labsdb_root_pass
    file { '/root/.my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('mariadb/root.my.cnf.erb'),
    }

}
