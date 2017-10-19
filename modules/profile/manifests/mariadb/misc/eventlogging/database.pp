# == Class profile::mariadb::eventlogging::database
#
# Configures the database settings for the Eventlogging master/replica.
#
# [*shard*]
#   Database shard
# [*master*]
#   Boolean value to establish if the host is acting as Master or Replica.
#
class profile::mariadb::misc::eventlogging::database (
    $shard  = hiera('profile::mariadb::eventlogging::database::shard'),
    $master = hiera('profile::mariadb::eventlogging::database::master'),
) {
    $mysql_role = $master ? {
        true  => 'master',
        false => 'slave',
    }

    include ::standard
    include passwords::misc::scripts
    include ::base::firewall

    # FIXME: including a role in a profile is not
    # allowed by our coding standard, but these needs to be
    # refactored on a separate change since they are broadly used.
    include role::mariadb::ferm
    include role::mariadb::monitor::dba

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
        config        => 'profile/mariadb/misc/eventlogging/eventlogging.my.cnf.erb',
        datadir       => '/srv/sqldata',
        tmpdir        => '/srv/tmp',
        read_only     => 0,
        ssl           => 'puppet-cert',
        p_s           => 'off',
        binlog_format => 'MIXED',
    }

    # FIXME: instanciating a role in a profile is not
    # allowed by our coding standard, but it needs to be
    # refactored on a separate change since it is broadly used.
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