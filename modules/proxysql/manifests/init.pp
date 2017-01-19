# Class proxysql

class proxysql (
    $admin_password,
    $datadir         = '/var/lib/proxysql',
    $admin_user      = 'admin',
    $admin_port      = 6032,
    $admin_interface = '127.0.0.1',
    $admin_socket    = '/tmp/proxysql_admin.sock',
    $mysql_port      = 6033,
    $mysql_interface = '0.0.0.0',
    $mysql_socket    = '/tmp/proxysql.sock',
    ) {

    package { [
        'proxysql',
        'mysql-client',
    ]:
        ensure => present,
    }

    file { '/etc/proxysql.cnf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('proxysql/proxysql.cnf.erb'),
    }

    file { '/root/.my.cnf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('proxysql/root.my.cnf.erb'),
    }
}
