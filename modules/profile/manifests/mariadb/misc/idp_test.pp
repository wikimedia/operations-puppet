# idp-test*.wikimedia.org db
class profile::mariadb::misc::idp_test {

    class { 'mariadb::packages_wmf': }

    include passwords::misc::scripts

    if os_version('debian >= buster') {
        $basedir = '/opt/wmf-mariadb104'
    } else {
        $basedir = '/opt/wmf-mariadb101'
    }
    class { 'mariadb::config':
        basedir       => $basedir,
        config        => 'role/mariadb/mysqld_config/misc.my.cnf.erb',
        datadir       => '/srv/sqldata',
        tmpdir        => '/srv/tmp',
        binlog_format => 'ROW',
        p_s           => 'on',
        read_only     => 0,
        ssl           => 'puppet-cert',
    }

    profile::mariadb::ferm { 'idp-test': }

    class { 'profile::mariadb::monitor::prometheus':
        mysql_group => 'misc',
        mysql_shard => 'idp-test',
        mysql_role  => 'standalone',
    }
    class { 'mariadb::monitor_disk':
        is_critical   => false,
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        is_critical   => false,
        contact_group => 'admins',
    }

    mariadb::monitor_readonly { [ 'idp-test' ]:
        read_only     => false,
        is_critical   => false,
        contact_group => 'admins',
    }

    ferm::service { 'idp-test':
        proto   => 'tcp',
        port    => '3306',
        notrack => true,
        srange  => '@resolve((idp-test1001.wikimedia.org idp-test2001.wikimedia.org))',
    }
}
