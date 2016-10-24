# role::labs::db::proxy
# Manages proxysql for the replica and other sql services on
# labs-support network

class role::labs::db::proxy {
    system::role { 'role::labs::db::proxy':
        description => 'LabsDB proxy',
    }

    include standard
    include passwords::labs::db::proxy

    $admin_user = $passwords::labs::db::proxy::admin_user
    $admin_password = $passwords::labs::db::proxy::admin_password

    class { 'proxysql':
        admin_user     => $admin_user,
        admin_password => $admin_password,
        admin_socket   => '/var/run/proxysql/proxysql_admin.sock',
        mysql_socket   => '/var/run/proxysql/proxysql_admin.sock',
        mysql_port     => 3306,
    }

    file {'/var/run/proxysql':
        ensure  => directory,
        owner   => 'proxysql',
        group   => 'root',
        mode    => '0755',
        require => Class['proxysql'],
    }

    nrpe::monitor_service { 'proxysql':
        description   => 'proxysql processes',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1: \
-a "proxysql"',
        critical      => false,
        contact_group => 'admins', # show on icinga/irc only
    }
}
