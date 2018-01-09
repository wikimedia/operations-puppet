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

    # Minimal basic config, with the right owner
    file { '/etc/proxysql.cnf':
        ensure  => present,
        owner   => 'proxysql',
        group   => 'proxysql',
        mode    => '0440',
        content => template('proxysql/proxysql.cnf.erb'),
    }

    # mostly sqlite internal config cache, let's make sure it has
    # the right owner
    file {'/var/lib/proxysql':
        ensure => directory,
        owner  => 'proxysql',
        group  => 'proxysql',
        mode   => '0750',
    }
}
