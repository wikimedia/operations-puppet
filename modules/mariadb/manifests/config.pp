# Please use separate .cnf templates for each type of server.
# Keep this independent and modular. It should be includable
# without the mariadb class.

# Accepted values for the $datadir parameter are:
# path_string | false

# Accepted values for the $semi_sync parameter are:
# 'off' | 'slave' | 'master' | 'both'

# Accepted values for the $replication_role parameter are:
# 'standalone' | 'slave' | 'master' | 'multisource_slave'

class mariadb::config(
    Stdlib::UnixPath $basedir,
    $config                  = 'mariadb/default.my.cnf.erb',
    $prompt                  = '\u@\h(\d)>\_',
    $password                = 'undefined',
    $datadir                 = '/srv/sqldata',
    $tmpdir                  = '/srv/tmp',
    $socket                  = '/run/mysqld/mysqld.sock',
    $port                    = 3306,
    $sql_mode                = '',
    $read_only               = 0,
    $p_s                     = 'off',
    $ssl                     = 'off',
    $ssl_ca                  = '',
    $ssl_cert                = '',
    $ssl_key                 = '',
    $ssl_verify_server_cert  = true,
    $binlog_format           = 'MIXED',
    $semi_sync               = 'off',
    $replication_role        = 'standalone',
    $max_allowed_packet      = '16M',
    $innodb_pool_size        = undef,
    $innodb_change_buffering = 'none',
    $event_scheduler         = 1,
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
    # Starting with buster, creation of /run/mysqld is done by setting:
    #   RuntimeDirectory=mysqld
    #   RuntimeDirectoryPreserve=yes
    # directly on the systemd unit
    if $socket == '/run/mysqld/mysqld.sock' and debian::codename::lt('buster') {
        systemd::tmpfile { 'mysqld':
            content => 'd /run/mysqld 0775 root mysql -',
        }
    }

    # Include these manually. If we're testing on systems with tarballs
    # instead of debs, the user won't exist.
    group { 'mysql':
        ensure => present,
        system => true,
    }

    user { 'mysql':
        ensure     => present,
        gid        => 'mysql',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    if $datadir {
        file { "${datadir}/my.cnf":
            ensure => absent,
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
    }

    file { '/usr/lib/nagios/plugins/check_mariadb.pl':
        ensure => absent,
    }

    nrpe::plugin { 'check_mariadb':
        source => 'puppet:///modules/icinga/check_mariadb.pl',
    }

    if ($ssl == 'on' or $ssl == 'puppet-cert') {

        # TODO: consider using profile::pki::get_cert
        # This creates also /etc/mysql/ssl
        puppet::expose_agent_certs { '/etc/mysql':
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

    $cleanup_files = ['/etc/mysql/my.cnf', '/usr/local/etc/my.cnf', "${basedir}/my.cnf",
                      '/etc/mysql/ssl/client-key.pem', '/etc/mysql/ssl/client-cert.pem',
                      '/etc/mysql/ssl/server-cert.pem']
    file {$cleanup_files:
        ensure  => absent,
    }
}
