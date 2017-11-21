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

    # We need to manualy setup users, as the package doesn't do it for us
    group { 'proxysql':
        ensure => present,
        system => true,
    }

    user { 'proxysql':
        ensure     => present,
        gid        => 'proxysql',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    file { '/etc/proxysql.cnf':
        ensure  => present,
        owner   => 'root',
        group   => 'root', # this is wrong, this should be its own group/user
        mode    => '0440',
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
