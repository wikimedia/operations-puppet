class profile::wmcs::services::toolsdb_primary {
    class { '::mariadb::packages_wmf': }
    class { '::mariadb::service': }
    include ::passwords::misc::scripts

    $socket = '/var/run/mysqld/mysqld.sock'

    class { 'profile::mariadb::monitor::prometheus':
        mysql_group => 'labs',
        mysql_role  => 'master',
        mysql_shard => 'tools',
        socket      => $socket,
    }

    class { 'mariadb::config':
        config        => 'role/mariadb/mysqld_config/tools.my.cnf.erb',
        datadir       => '/srv/labsdb/data',
        basedir       => '/opt/wmf-mariadb101',
        tmpdir        => '/srv/labsdb/tmp',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
        read_only     => 'OFF',
        socket        => $socket,
    }
}
