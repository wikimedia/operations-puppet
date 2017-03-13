# Please use separate .cnf templates for each type of server.
# Keep this independent and modular. It should be includable
# without the mariadb class.

# Accepted values for the $semi_sync parameter are:
# 'off' | 'slave' | 'master' | 'both'

# Accepted values for the $replication_role parameter are:
# 'standalone' | 'slave' | 'master' | 'multisource_slave'

class mariadb::config(
    $config                 = 'mariadb/default.my.cnf.erb',
    $prompt                 = '\u@\h(\d)> ',
    $password               = 'undefined',
    $datadir                = '/srv/sqldata',
    $tmpdir                 = '/srv/tmp',
    $socket                 = '/var/run/mysqld/mysqld.sock',
    $port                   = 3306,
    $sql_mode               = '',
    $read_only              = 0,
    $p_s                    = 'off',
    $ssl                    = 'off',
    $ssl_ca                 = '',
    $ssl_cert               = '',
    $ssl_key                = '',
    $ssl_verify_server_cert = true,
    $binlog_format          = 'MIXED',
    $semi_sync              = 'off',
    $replication_role       = 'standalone',
    $max_allowed_packet     = '16M',
    ) {

    $server_id = inline_template(
        "<%= @ipaddress.split('.').inject(0)\
{|total,value| (total << 8 ) + value.to_i} %>"
    )

    $gtid_domain_id = inline_template(
        "<%= @ipaddress.split('.').inject(0)\
{|total,value| (total << 8 ) + value.to_i} %>"
    )

    file { '/etc/my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template($config),
    }

    file { '/etc/mysql':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/etc/mysql/grcat.config':
        ensure => present,
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/mariadb/grcat.config',
    }

    # if the socket location is different from the default, it is the role
    # class' reponsability to handle it (otherwise this could have side
    # efects, like changing / or /tmp permissions
    if $socket == '/var/run/mysqld/mysqld.sock' {
        file { '/var/run/mysqld':
            ensure => directory,
            mode   => '0775',
            owner  => 'root',
            group  => 'mysql',
        }
    }

    file { '/etc/mysql/my.cnf':
        ensure  => absent,
        require => File['/etc/mysql'],
    }

    file { '/usr/local/etc/my.cnf':
        ensure => absent,
    }
    file { "${datadir}/my.cnf":
        ensure => absent,
    }
    file { '/opt/wmf-mariadb10/my.cnf':
        ensure => absent,
    }

    # Include these manually. If we're testing on systems with tarballs
    # instead of debs, the user won't exist.
    if os_version('debian >= stretch') {
        group { 'mysql':
            ensure => present,
            system => true,
        }
    }
    else {
        group { 'mysql':
            ensure => present,
        }
    }

    user { 'mysql':
        ensure     => present,
        gid        => 'mysql',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    file { $datadir:
        ensure => directory,
        owner  => 'mysql',
        group  => 'mysql',
        mode   => '0755',
    }

    file { $tmpdir:
        ensure => directory,
        owner  => 'mysql',
        group  => 'mysql',
        mode   => '0755',
    }

    file { '/usr/lib/nagios/plugins/check_mariadb.pl':
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/icinga/check_mariadb.pl',
    }

    if ($ssl == 'on' or $ssl == 'puppet-cert') {

        # This creates also /etc/mysql/ssl
        ::base::expose_puppet_certs { '/etc/mysql':
            ensure          => present,
            provide_private => true,
            user            => 'mysql',
            group           => 'mysql',
        }

        file { '/etc/mysql/ssl/cacert.pem':
            ensure    => file,
            owner     => 'root',
            group     => 'mysql',
            mode      => '0440',
            show_diff => false,
            backup    => false,
            content   => secret('mysql/cacert.pem'),
        }
        file { '/etc/mysql/ssl/server-key.pem':
            ensure    => file,
            owner     => 'root',
            group     => 'mysql',
            mode      => '0440',
            show_diff => false,
            backup    => false,
            content   => secret('mysql/server-key.pem'),
        }
    }

    file { '/etc/mysql/ssl/server-cert.pem':
        ensure => absent,
    }
    file { '/etc/mysql/ssl/client-key.pem':
        ensure => absent,
    }
    file { '/etc/mysql/ssl/client-cert.pem':
        ensure => absent,
    }

}
