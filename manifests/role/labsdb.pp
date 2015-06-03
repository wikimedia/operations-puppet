#include "mysql.db"

class role::labs::db::master {

    system::role { 'role::labs::db::master':
        description => 'Labs user database master',
    }

    include standard
    include mariadb::packages_wmf
    include role::mariadb::grants
    include role::mariadb::monitor

    class { 'mariadb::config':
        prompt   => 'TOOLSDB',
        config   => 'mariadb/toolsmaster.my.cnf.erb',
        password => $passwords::misc::scripts::mysql_root_pass,
        datadir  => '/srv/labsdb/data',
        tmpdir   => '/tmp',
    }

}
