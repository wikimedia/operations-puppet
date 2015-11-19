class role::labs::db::master {

    system::role { 'role::labs::db::master':
        description => 'Labs user database master',
    }

    include standard
    class { 'mariadb::packages_wmf':
        mariadb10 => false
    }
    include role::mariadb::grants
    include role::mariadb::monitor

    class { 'mariadb::config':
        prompt    => 'TOOLSDB master',
        config    => 'mariadb/tools.my.cnf.erb',
        password  => $passwords::misc::scripts::mysql_root_pass,
        datadir   => '/srv/labsdb/data',
        tmpdir    => '/tmp',
        read_only => 'OFF',
    }
}
