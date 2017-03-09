# Eventlogging needs to be sandboxed by itself. It can consume resources
# unpredictably, especially during backfilling. It also benefits greatly
# from a setup tuned for TokuDB.
class role::mariadb::misc::eventlogging(
    $shard  = 'm4',
    $master = false,
    ) {

    system::role { 'role::mariadb::misc':
        description => 'Eventlogging Database',
    }

    $mysql_role = $master ? {
        true  => 'master',
        false => 'slave',
    }

    include ::standard
    include role::mariadb::monitor::dba
    include passwords::misc::scripts
    include role::mariadb::ferm

    class {'role::mariadb::groups':
        mysql_group => 'misc',
        mysql_shard => $shard,
        mysql_role  => $mysql_role,
    }

    include mariadb::packages_wmf
    include mariadb::service

    $read_only = $master ? {
        true  => 0,
        false => 1,
    }

    class { 'mariadb::config':
        config        => 'role/mariadb/mysqld_config/eventlogging.my.cnf.erb',
        datadir       => '/srv/sqldata',
        tmpdir        => '/srv/tmp',
        read_only     => $read_only,
        ssl           => 'puppet-cert',
        p_s           => 'off',
        binlog_format => 'MIXED',
    }

    class { 'role::mariadb::grants::production':
        shard    => $shard,
        prompt   => "EVENTLOGGING ${shard}",
        password => $passwords::misc::scripts::mysql_root_pass,
    }

    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => $master,
    }
}

