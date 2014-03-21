
# Generic Server
class role::mariadb {

    $cluster = 'misc'

    system::role { 'role::mariadb':
        description => 'database server',
    }

    include mariadb
}

# Beta Cluster Master
# Should add separate role for slaves
class role::mariadb::beta {

    $cluster = 'beta'

    system::role { 'role::mariadb::beta':
        description => 'beta cluster database server',
    }

    include mariadb::packages
    include mariadb::beta::config
}

# What db1044 presently does...
class role::mariadb::tendril {

    $cluster = 'mysql'

    system::role { 'role::mariadb::tendril':
        description => 'tendril database server',
    }

    include mariadb::packages
    include mariadb::tendril::config
}
