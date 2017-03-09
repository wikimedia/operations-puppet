# tendril.wikimedia.org db
class role::mariadb::tendril {

    system::role { 'role::mariadb::tendril':
        description => 'tendril database server',
    }

    include mariadb::packages_wmf
    include mariadb::service

    include ::standard
    include role::mariadb::monitor::dba
    include passwords::misc::scripts
    include role::mariadb::ferm

    class {'role::mariadb::groups':
        mysql_group => 'tendril',
        mysql_role  => 'standalone',
    }

    class { 'mariadb::config':
        config  => 'role/mariadb/mysqld_config/tendril.my.cnf.erb',
        datadir => '/srv/sqldata',
        tmpdir  => '/srv/tmp',
        ssl     => 'puppet-cert',
    }
}

