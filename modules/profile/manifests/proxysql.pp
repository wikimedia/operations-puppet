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

    # Starting with buster, creation of /run/proxysql is done by setting:
    #   RuntimeDirectory=mysqld
    #   RuntimeDirectoryPreserve=yes
    # directly on the systemd unit
    if !os_version('debian >= buster'){
        systemd::tmpfile { 'proxysql':
            content => 'd /run/proxysql 0775 proxysql proxysql -',
        }
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

    # With systemd there should be only 1 process running
    nrpe::monitor_service { 'proxysql':
        description   => 'proxysql processes',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C proxysql',
        critical      => false,
        contact_group => 'admins', # show on icinga/irc only
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Proxysql',
    }
}
