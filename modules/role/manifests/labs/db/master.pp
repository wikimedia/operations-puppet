class role::labs::db::master {

    system::role { 'role::labs::db::master':
        description => 'Labs user database master',
    }

    include standard
    class { 'mariadb::packages_wmf':
        mariadb10 => false
    }
    include role::mariadb::monitor
    include passwords::misc::scripts

    class { 'role::mariadb::groups':
        mysql_group => 'labs',
        mysql_role  => 'master',
        mysql_shard => 'tools',
    }

    class { 'mariadb::config':
        config    => 'mariadb/tools.my.cnf.erb',
        datadir   => '/srv/labsdb/data',
        tmpdir    => '/tmp',
        read_only => 'OFF',
    }
}
