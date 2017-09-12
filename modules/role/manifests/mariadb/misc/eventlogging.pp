# Eventlogging needs to be sandboxed by itself. It can consume resources
# unpredictably, especially during backfilling. It also benefits greatly
# from a setup tuned for TokuDB.
class role::mariadb::misc::eventlogging(
    $shard  = 'm4',
    $master = false,
    ) {

    system::role { 'mariadb::misc':
        description => 'Eventlogging Database',
    }

    $mysql_role = $master ? {
        true  => 'master',
        false => 'slave',
    }

    include ::standard
    include role::mariadb::monitor::dba
    include passwords::misc::scripts
    include ::base::firewall
    include role::mariadb::ferm

    class {'role::mariadb::groups':
        mysql_group => 'misc',
        mysql_shard => $shard,
        mysql_role  => $mysql_role,
        socket      => '/tmp/mysql.sock',
    }

    include mariadb::packages_wmf
    include mariadb::service


    # History context: there used to be a distinction between
    # EL master and slaves, namely that only the master was not
    # in read only mode. The Analytics team removed this constraint
    # before deploying the eventlogging_cleaner script (T156933),
    # that needed to DELETE/UPDATE rows on the job database without
    # running as root for obvious reasons.
    class { 'mariadb::config':
        config        => 'role/mariadb/mysqld_config/eventlogging.my.cnf.erb',
        datadir       => '/srv/sqldata',
        tmpdir        => '/srv/tmp',
        read_only     => 0,
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
        socket     => '/tmp/mysql.sock',
    }
}

