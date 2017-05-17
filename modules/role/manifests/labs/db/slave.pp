class role::labs::db::slave {

    system::role { 'labs::db::slave':
        description => 'Labs user database slave',
    }

    include ::standard
    include mariadb::packages_wmf
    include mariadb::service
    include role::mariadb::monitor
    include role::mariadb::ferm
    include passwords::misc::scripts

    # FIXME: Add the socket location to make the transition easier.
    $socket = '/var/run/mysqld/mysqld.sock'

    class { 'role::mariadb::groups':
        mysql_group => 'labs',
        mysql_role  => 'slave',
        mysql_shard => 'tools',
        socket      => $socket,
    }

    class { 'mariadb::config':
        config        => 'role/mariadb/mysqld_config/tools.my.cnf.erb',
        datadir       => '/srv/labsdb/data',
        tmpdir        => '/srv/labsdb/tmp',
        read_only     => 'ON',
        p_s           => 'on',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
        socket        => $socket,
    }

    #mariadb::monitor_replication { 'tools':
    #    multisource   => false,
    #    contact_group => 'labs',
    #}
}
