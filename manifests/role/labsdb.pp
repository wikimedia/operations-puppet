#include "mysql.db"

class role::labs::db::master {

    system::role { 'role::labs::db::master':
        description => 'Labs user database master',
    }

    include standard
    class { 'mariadb::packages_wmf':
        mariadb10 => false, # remove this on upgrade
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

class role::labs::db::slave {

    system::role { 'role::labs::db::slave':
        description => 'Labs user database slave',
    }

    include standard
    include mariadb::packages_wmf
    include role::mariadb::grants
    include role::mariadb::monitor
    include role::mariadb::ferm

    class { 'mariadb::config':
        prompt    => 'TOOLSDB slave',
        config    => 'mariadb/tools.my.cnf.erb',
        password  => $passwords::misc::scripts::mysql_root_pass,
        datadir   => '/srv/labsdb/data',
        tmpdir    => '/srv/labsdb/tmp',
        read_only => 'ON',
    }

    #mariadb::monitor_replication { 'tools':
    #    multisource   => false,
    #    contact_group => 'labs',
    #}
}
