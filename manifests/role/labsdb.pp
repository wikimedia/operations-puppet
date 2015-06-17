#include "mysql.db"

class role::labs::db (
    $role = 'master',
    ) {

    system::role { 'role::labs::db::master':
        description => "Labs user database ${role}",
    }

    include standard
    include mariadb::packages_wmf
    include role::mariadb::grants
    include role::mariadb::monitor

    $read_only = $role ? {
        'master' => 'OFF',
        'slave'  => 'ON',
    }

    class { 'mariadb::config':
        prompt    => "TOOLSDB ${role}",
        config    => "mariadb/tools.my.cnf.erb",
        password  => $passwords::misc::scripts::mysql_root_pass,
        datadir   => '/srv/labsdb/data',
        tmpdir    => '/tmp',
        read_only => $read_only,
    }

    #unless $role == 'master' {
    #    mariadb::monitor_replication { 'tools':
    #        multisource   => false,
    #        contact_group => 'labs',
    #    }
    #}

}

class role::labs::db::master {
    class { 'role::labs::db':
        role => 'master',
    }
}

class role::labs::db::slave {
    class { 'role::labs::db':
        role => 'slave',
    }
}

