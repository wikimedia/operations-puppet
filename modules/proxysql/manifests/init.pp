# Class proxysql

class proxysql (
    $admin_password,
    $datadir         = '/var/lib/proxysql',
    $admin_user      = 'admin',
    $admin_port      = 6032,
    $admin_interface = '127.0.0.1',
    $admin_socket    = '/run/proxysql_admin.sock',
    $mysql_port      = 6033,
    $mysql_interface = '0.0.0.0',
    $mysql_socket    = '/run/proxysql.sock',
    ) {

    # install the proxy and the user/group
    package { 'proxysql':
        ensure => installed,
    }    

    # Minimal basic config, with the right owner
    file { '/etc/proxysql.cfg':
        ensure  => present,
        owner   => 'proxysql',
        group   => 'proxysql',
        mode    => '0440',
        content => template('proxysql/proxysql.cnf.erb'),
        requite => Package['proxysql'],
    }
}
