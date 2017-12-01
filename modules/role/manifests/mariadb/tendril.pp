# tendril.wikimedia.org db
class role::mariadb::tendril {

    system::role { 'mariadb::tendril':
        description => 'tendril database server',
    }

    include mariadb::packages_wmf
    include mariadb::service

    include ::standard
    class { 'profile::mariadb::monitor::dba': }
    include passwords::misc::scripts
    class { 'profile::base::firewall': }
    include role::mariadb::ferm

    class { 'profile::mariadb::monitor::prometheus':
        mysql_group => 'tendril',
        mysql_role  => 'standalone',
        socket      => '/tmp/mysql.sock',
    }

    class { 'mariadb::config':
        config  => 'role/mariadb/mysqld_config/tendril.my.cnf.erb',
        datadir => '/srv/sqldata',
        tmpdir  => '/srv/tmp',
        ssl     => 'puppet-cert',
    }
}

