# idp-test*.wikimedia.org db
class profile::mariadb::misc::idp_test {

    class { 'mariadb::packages_wmf': }

    $mysql_role = 'standalone'
    $section = 'idp-test'

    class { '::profile::mariadb::mysql_role':
        role => $mysql_role,
    }
    profile::mariadb::section { $section: }

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

    profile::mariadb::ferm { $section: }

    class { 'profile::mariadb::monitor::prometheus':
        mysql_group => 'misc',
        mysql_shard => 'idp-test',
        mysql_role  => $mysql_role,
    }
    class { 'mariadb::monitor_disk':
        is_critical   => false,
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        is_critical   => false,
        contact_group => 'admins',
    }

    mariadb::monitor_readonly { $section:
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
