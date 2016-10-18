# Class proxysql

class proxysql (
    $datadir         = '/var/lib/proxysql'
    $admin_user      = 'admin',
    $admin_password,
    $admin_port      = 6032,
    $admin_interface = '127.0.0.1',
    $admin_socket    = '/tmp/proxysql_admin.sock',
    $mysql_interface = '0.0.0.0',
    $mysql_port      = 6033,
    $mysql_socket    = '/tmp/proxysql.sock',
    ) {

    package { 'proxysql':
        ensure => present,
    }

    file { '/etc/proxysql.cnf':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('proxysql/proxysql.cnf.erb'),
    }

}
