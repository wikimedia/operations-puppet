# = Class: profile::wmcs::services::toolsdb_secondary
#
# This class sets up a the Cloud VPS project libraryupgrader.
#
class profile::wmcs::services::toolsdb_secondary{
    class { '::mariadb::packages_wmf': }
    class { '::mariadb::service': }
    include ::passwords::misc::scripts

    # FIXME: Add the socket location to make the transition easier.
    $socket = '/var/run/mysqld/mysqld.sock'

    class { 'mariadb::config':
        config        => 'role/mariadb/mysqld_config/tools.my.cnf.erb',
        datadir       => '/srv/labsdb/data',
        tmpdir        => '/srv/labsdb/tmp',
        basedir       => '/opt/wmf-mariadb101',
        read_only     => 'ON',
        p_s           => 'on',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
        socket        => $socket,
    }

    #mariadb::monitor_replication { 'tools':
    #    multisource   => false,
    #    contact_group => 'labs',
    #}
}
