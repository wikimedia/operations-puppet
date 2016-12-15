# hosts with client utilities to conect to remote servers
# do not mix with other mariadb/mysql full server installations
class role::mariadb::client {
    include mariadb::packages_client
    include passwords::misc::scripts

    class { 'mariadb::config':
        config => 'role/mariadb/mysqld_config/client.my.cnf.erb',
        ssl    => 'puppet-cert',
    }

    $root_pass = $passwords::misc::scripts::mysql_root_pass
    $prompt = '\h'
    file { '/root/.my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('mariadb/root.my.cnf.erb'),
    }

}
