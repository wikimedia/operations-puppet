# = Class: profile::wmcs::services::toolsdb_secondary
#
# This class sets up MariaDB for a secondary tools database.
#
class profile::wmcs::services::toolsdb_secondary (
) {
    require profile::wmcs::services::toolsdb_apt_pinning

    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    class { '::mariadb::service': }
    include ::passwords::misc::scripts

    # FIXME: Add the socket location to make the transition easier.
    $socket = '/var/run/mysqld/mysqld.sock'

    class { 'mariadb::config':
        config        => 'role/mariadb/mysqld_config/tools.my.cnf.erb',
        datadir       => '/srv/labsdb/data',
        tmpdir        => '/srv/labsdb/tmp',
        basedir       => $profile::mariadb::packages_wmf::basedir,
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
