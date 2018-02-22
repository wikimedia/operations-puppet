# tendril.wikimedia.org db
class profile::mariadb::misc::tendril {

    include mariadb::packages_wmf

    require_package('libodbc1') # hack to fix CONNECT dependency

    include ::profile::mariadb::monitor::dba
    include passwords::misc::scripts

    class { 'profile::mariadb::monitor::prometheus':
        mysql_group => 'misc',
        mysql_shard => 'tendril',
        mysql_role  => 'standalone', # FIXME
    }

    class { 'mariadb::config':
        config        => 'profile/mariadb/mysqld_config/tendril.my.cnf.erb',
        datadir       => '/srv/sqldata',
        basedir       => '/opt/wmf-mariadb101',
        tmpdir        => '/srv/tmp',
        binlog_format => 'ROW',
        ssl           => 'puppet-cert',
    }
}
