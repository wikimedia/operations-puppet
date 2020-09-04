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
    String  $shard  = lookup('profile::mariadb::misc::eventlogging::database::shard'),
    Boolean $master = lookup('profile::mariadb::misc::eventlogging::database::master'),
) {
    $mysql_role = $master ? {
        true  => 'master',
        false => 'slave',
    }

    class { 'passwords::misc::scripts': }

    class { 'mariadb::monitor_disk':
        is_critical   => $master,
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        is_critical   => $master,
        contact_group => 'admins',
    }

    include profile::mariadb::monitor::prometheus

    mariadb::monitor_readonly { [ $shard ]:
        read_only     => true,
        is_critical   => false,
        contact_group => 'admins',
    }

    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    require_package ('mydumper')

    class { 'mariadb::service': }

    $mariadb_socket = '/run/mysqld/mysqld.sock'

    # History context: there used to be two hosts with the 'log'
    # database, on representing the master and the other the replica.
    # After T159170 we keep only one instance as read-only replica
    # in case historical queries are needed (for data not yet in Hadoop).
    class { 'mariadb::config':
        basedir       => $profile::mariadb::packages_wmf::basedir,
        config        => 'profile/mariadb/misc/eventlogging/eventlogging.my.cnf.erb',
        datadir       => '/srv/sqldata',
        tmpdir        => '/srv/tmp',
        socket        => $mariadb_socket,
        port          => 3306,
        read_only     => 1,
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
}
