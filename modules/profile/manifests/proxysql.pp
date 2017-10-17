# role::labs::db::proxy
# Manages proxysql for the replica and other sql services on
# labs-support network

class profile::proxysql {
    include ::passwords::misc::scripts

    $admin_user = 'root'
    $admin_password = $::passwords::misc::scripts::mysql_root_pass

    class { '::proxysql':
        admin_user     => $admin_user,
        admin_password => $admin_password,
        admin_socket   => '/run/proxysql/proxysql_admin.sock',
        mysql_socket   => '/run/proxysql/proxysql.sock',
        mysql_port     => 3311,
    }

    ferm::service { 'proxysql_mysql':
        proto   => 'tcp',
        port    => '3311',
        notrack => true,
    }

    file {'/run/proxysql':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Class['proxysql'],
    }

    nrpe::monitor_service { 'proxysql':
        description   => 'proxysql processes',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 2:2 -C proxysql',
        critical      => false,
        contact_group => 'admins', # show on icinga/irc only
    }
}
