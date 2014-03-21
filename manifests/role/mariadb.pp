
class role::mariadb::beta {

    $cluster = 'beta'

    system::role { 'role::mariadb::beta':
        description => 'beta cluster database server',
    }

    include mariadb::user
    include mariadb::beta::config
    include mariadb::sources
    include mariadb::packages
    include mariadb::beta::datadir
}

class role::mariadb::beta_slave {

    $cluster = 'beta'

    system::role { 'role::mariadb::beta_slave':
        description => 'beta cluster slave database server',
    }

    include mariadb::user
    include mariadb::beta::config_slave
    include mariadb::sources
    include mariadb::packages
    include mariadb::beta::datadir
}

class role::mariadb::tendril {

    $cluster = 'mysql'

    system::role { 'role::mariadb::tendril':
        description => 'tendril database server',
    }

    include mariadb::user
    include mariadb::tendril::config
    include mariadb::sources
    include mariadb::packages
    include mariadb::datadir
}
