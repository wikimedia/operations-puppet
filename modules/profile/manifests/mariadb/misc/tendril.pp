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

    mariadb::monitor_readonly { [ 'tendril' ]:
        read_only     => false,
        is_critical   => false,
        contact_group => 'dba',
    }

    if os_version('debian >= buster') {
        $basedir = '/opt/wmf-mariadb104'
    } else {
        $basedir = '/opt/wmf-mariadb101'
    }
    class { 'mariadb::config':
        basedir       => $basedir,
        config        => 'profile/mariadb/mysqld_config/tendril.my.cnf.erb',
        datadir       => '/srv/sqldata',
        tmpdir        => '/srv/tmp',
        binlog_format => 'ROW',
        p_s           => 'on',
        ssl           => 'puppet-cert',
    }

    # Firewall rules for the tendril db hosts so they can be accessed
    # by tendril and dbtree web server (on a public ip)
    ferm::service { 'tendril-backend':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve((dbmonitor1001.wikimedia.org dbmonitor2001.wikimedia.org))',
    }
}
