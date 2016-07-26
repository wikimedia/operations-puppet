class role::labs::db::replica {

    system::role { 'role::labs::db::replica':
        description => 'Labs replica database',
    }

    include standard
    class { 'mariadb::packages_wmf':
        mariadb10 => true
    }
    include role::mariadb::grants
    include role::mariadb::monitor
    include role::mariadb::ferm

    class { 'mariadb::config':
        prompt        => 'REPLICA database',
        config        => 'mariadb/labsdb-replica.my.cnf.erb',
        password      => $passwords::misc::scripts::mysql_root_pass,
        datadir       => '/srv/labsdb/data',
        tmpdir        => '/srv/labsdb/tmp',
        read_only     => 'ON',
        p_s           => 'on',
        ssl           => 'on',
        binlog_format => 'ROW',
    }

}
