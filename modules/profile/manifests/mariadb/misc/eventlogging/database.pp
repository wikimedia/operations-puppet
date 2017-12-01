# == Class profile::mariadb::misc::eventlogging::database
#
# Configures the database settings for the Eventlogging master/replica.
#
# [*shard*]
#   Database shard
# [*master*]
#   Boolean value to establish if the host is acting as Master or Replica.
#
class profile::mariadb::misc::eventlogging::database (
    $shard  = hiera('profile::mariadb::misc::eventlogging::database::shard'),
    $master = hiera('profile::mariadb::misc::eventlogging::database::master'),
) {

    validate_bool($master)

    $mysql_role = $master ? {
        true  => 'master',
        false => 'slave',
    }

    class { 'passwords::misc::scripts': }

    class { 'profile::mariadb::monitor::prometheus':
        mysql_group => 'misc',
        mysql_shard => $shard,
        mysql_role  => $mysql_role,
    }

    class { 'mariadb::packages_wmf': }
    class { 'mariadb::service': }

    if os_version('debian >= stretch') {
        $mariadb_basedir = '/opt/wmf-mariadb101'
        $mariadb_socket = '/run/mysqld/mysqld.sock'
    } else {
        $mariadb_basedir = '/opt/wmf-mariadb10'
        $mariadb_socket = '/tmp/mysql.sock'
    }

    # History context: there used to be a distinction between
    # EL master and slaves, namely that only the master was not
    # in read only mode. The Analytics team removed this constraint
    # before deploying the eventlogging_cleaner script (T156933),
    # that needed to DELETE/UPDATE rows on the job database without
    # running as root for obvious reasons.
    class { 'mariadb::config':
        basedir       => $mariadb_basedir,
        config        => 'profile/mariadb/misc/eventlogging/eventlogging.my.cnf.erb',
        datadir       => '/srv/sqldata',
        tmpdir        => '/srv/tmp',
        socket        => $mariadb_socket,
        port          => 3306,
        read_only     => 0,
        ssl           => 'puppet-cert',
        p_s           => 'off',
        binlog_format => 'MIXED',
    }

    # FIXME: instantiating a role in a profile is not
    # allowed by our coding standard, but it needs to be
    # refactored on a separate change since it is broadly used.
    class { 'profile::mariadb::grants::production':
        shard    => $shard,
        prompt   => "EVENTLOGGING ${shard}",
        password => $passwords::misc::scripts::mysql_root_pass,
    }

    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => $master,
        socket     => $mariadb_socket,
    }
}
