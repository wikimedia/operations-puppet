# tendril.wikimedia.org db
class profile::mariadb::misc::tendril {

    include mariadb::packages_wmf

    include ::profile::mariadb::monitor::dba
    include passwords::misc::scripts

    class { 'profile::mariadb::monitor::prometheus':
        mysql_group => 'misc',
        mysql_shard => 'tendril',
        mysql_role  => 'standalone',
    }

    class { 'mariadb::config':
        config  => 'profile/mariadb/mysqld_config/tendril.my.cnf.erb',
        datadir => '/srv/sqldata',
        tmpdir  => '/srv/tmp',
        ssl     => 'puppet-cert',
    }
}
