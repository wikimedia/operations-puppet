# tendril.wikimedia.org db
class role::mariadb::tendril {

    system::role { 'role::mariadb::tendril':
        description => 'tendril database server',
    }

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    include standard
    include role::mariadb::monitor::dba
    include passwords::misc::scripts
    include role::mariadb::ferm

    class {'role::mariadb::groups':
        mysql_group => 'tendril',
        mysql_role  => 'standalone',
    }

    ferm::service { 'memcached_tendril':
        proto  => 'tcp',
        port   => '11211',
        srange => '@resolve(neon.wikimedia.org)',
    }

    class { 'mariadb::config':
        config  => 'mariadb/tendril.my.cnf.erb',
        datadir => '/srv/sqldata',
        tmpdir  => '/srv/tmp',
    }
}

