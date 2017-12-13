# profile::proxysql
# Manages proxysql service on a host to allow connections to a mysql server

class profile::proxysql {
    include ::passwords::misc::scripts

    $admin_user = 'root'
    $admin_password = $::passwords::misc::scripts::mysql_root_pass
    $admin_socket = '/run/proxysql/proxysql_admin.sock'
    $mysql_socket = '/run/proxysql/proxysql.sock'
    $mysql_port   = 3311

    class { '::proxysql':
        admin_user     => $admin_user,
        admin_password => $admin_password,
        admin_socket   => $admin_socket,
        mysql_socket   => $mysql_socket,
        mysql_port     => $mysql_port,
    }

    # Let's not open the proxy port for now, only allow localhost connections
    #ferm::service { 'proxysql_mysql':
    #    proto   => 'tcp',
    #    port    => $mysql_port,
    #    notrack => true,
    #}

    # we need to setup the service, as by default there is only an init.d script
    # that start as root. We will not start it by default, but will have monitoring
    # to check it is running. We can change that in the future.
    systemd::unit { 'proxysql':
        ensure  => present,
        content => systemd_template('proxysql'),
        require => Class['proxysql'],
    }

    file {'/run/proxysql':
        ensure  => directory,
        owner   => 'proxysql',
        group   => 'proxysql',
        mode    => '0755',
        require => Class['proxysql'],
    }

    # Let's add proxysql user to the mysql group so it can access mysql's
    # tls client certs
    exec { 'proxysql membership to mysql':
        unless  => '/usr/bin/getent group mysql | /usr/bin/cut -d: -f4 | /bin/grep -q proxysql',
        command => '/usr/sbin/usermod -a -G mysql proxysql',
        require => Class['proxysql'],
    }

    # lets simplify connections from root
    file { '/root/.my.cnf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('profile/proxysql/root.my.cnf.erb'),
    }

    # I think with systemd there should be only 1 process running ?
    nrpe::monitor_service { 'proxysql':
        description   => 'proxysql processes',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C proxysql',
        critical      => false,
        contact_group => 'admins', # show on icinga/irc only
    }
}
