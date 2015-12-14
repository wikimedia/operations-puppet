class role::labs::db::slave {

    system::role { 'role::labs::db::slave':
        description => 'Labs user database slave',
    }

    include standard
    class { 'mariadb::packages_wmf':
        mariadb10 => true
    }
    include role::mariadb::grants
    include role::mariadb::monitor
    include role::mariadb::ferm

    class { 'mariadb::config':
        prompt        => 'TOOLSDB slave',
        config        => 'mariadb/tools.my.cnf.erb',
        password      => $passwords::misc::scripts::mysql_root_pass,
        datadir       => '/srv/labsdb/data',
        tmpdir        => '/srv/labsdb/tmp',
        read_only     => 'ON',
        p_s           => 'on',
        ssl           => 'on',
        binlog_format => 'ROW',
    }

    #mariadb::monitor_replication { 'tools':
    #    multisource   => false,
    #    contact_group => 'labs',
    #}
}
