# MariaDB 10 slaves replicating all shards and running TokuDB
class role::mariadb::dbstore(
    $lag_warn = 300,
    $lag_crit = 600,
    $warn_stopped = true,
    ) {

    system::role { 'role::mariadb::dbstore':
        description => 'Delayed Slave',
    }

    include mariadb::packages_wmf
    include mariadb::service

    include ::standard
    include passwords::misc::scripts

    class { 'role::mariadb::grants::production':
        password => $passwords::misc::scripts::mysql_root_pass,
        prompt   => 'DBSTORE',
    }

    include role::mariadb::monitor::dba
    include passwords::misc::scripts
    include role::mariadb::ferm

    class {'role::mariadb::groups':
        mysql_group => 'dbstore',
        mysql_role  => 'slave',
    }

    class { 'mariadb::config':
        config  => 'mariadb/dbstore.my.cnf.erb',
        datadir => '/srv/sqldata',
        tmpdir  => '/srv/tmp',
        ssl     => 'puppet-cert',
        p_s     => 'off',
    }

    mariadb::monitor_replication {
        ['s1','s2','s3','s4','s5','s6','s7','m2','m3','x1']:
        is_critical   => false,
        contact_group => 'admins', # only show on nagios/irc
        lag_warn      => $lag_warn,
        lag_crit      => $lag_crit,
        warn_stopped  => $warn_stopped,
    }
}
