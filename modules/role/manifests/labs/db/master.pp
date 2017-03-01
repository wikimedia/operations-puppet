class role::labs::db::master {

    system::role { 'role::labs::db::master':
        description => 'Labs user database master',
    }

    include ::standard
    include mariadb::packages_wmf
    include mariadb::service
    include role::mariadb::monitor
    include passwords::misc::scripts

    socket = '/var/run/mysqld/mysqld.sock'
    class { 'role::mariadb::groups':
        mysql_group => 'labs',
        mysql_role  => 'master',
        mysql_shard => 'tools',
        socket      => $socket,
    }

    class { 'mariadb::config':
        config    => 'role/mariadb/mysqld_config/tools.my.cnf.erb',
        datadir   => '/srv/labsdb/data',
        socket    => $socket,
        tmpdir    => '/tmp',
        ssl       => 'puppet-cert',
        read_only => 'OFF',
    }
}
