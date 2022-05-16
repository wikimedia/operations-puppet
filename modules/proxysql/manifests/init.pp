# SPDX-License-Identifier: Apache-2.0
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

    # Install package
    ensure_packages ('proxysql')

    # Users are setup by the package

    # Minimal basic config, with the right owner
    file { '/etc/proxysql.cnf':
        ensure  => present,
        owner   => 'proxysql',
        group   => 'proxysql',
        mode    => '0440',
        content => template('proxysql/proxysql.cnf.erb'),
        require => Package['proxysql'],
    }

    # mostly sqlite internal config cache, let's make sure it has
    # the right owner
    # It should be handled automatically by the package
    #file {'/var/lib/proxysql':
    #    ensure => directory,
    #    owner  => 'proxysql',
    #    group  => 'proxysql',
    #    mode   => '0750',
    #}
}
