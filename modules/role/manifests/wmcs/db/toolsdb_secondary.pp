class role::wmcs::db::toolsdb_secondary {

    system::role { 'wmcs::db::toolsdb_secondary':
        description => 'Cloud user database secondary',
    }

    include ::profile::mariadb::monitor
    include ::role::mariadb::ferm
    include ::profile::wmcs::services::toolsdb_secondary

    # FIXME: Add the socket location to make the transition easier.
    $socket = '/var/run/mysqld/mysqld.sock'

    class { 'profile::mariadb::monitor::prometheus':
        mysql_group => 'labs',
        mysql_role  => 'slave',
        mysql_shard => 'tools',
        socket      => $socket,
    }

}
