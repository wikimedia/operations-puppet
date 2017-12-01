class role::labs::db::master {

    system::role { 'labs::db::master':
        description => 'Labs user database master',
    }

    include ::standard
    include ::mariadb::packages_wmf
    include ::mariadb::service
    include ::profile::mariadb::monitor
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
        tmpdir        => '/srv/labsdb/tmp',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
        read_only     => 'OFF',
        socket        => $socket,
    }
}
