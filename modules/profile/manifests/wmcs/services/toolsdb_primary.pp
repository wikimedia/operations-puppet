class profile::wmcs::services::toolsdb_primary (
) {
    require profile::wmcs::services::toolsdb_apt_pinning

    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    class { '::mariadb::service': }
    include ::passwords::misc::scripts

    $socket = '/var/run/mysqld/mysqld.sock'

    class { 'profile::mariadb::monitor::prometheus':
        socket      => $socket,
    }

    class { 'mariadb::config':
        config        => 'role/mariadb/mysqld_config/tools.my.cnf.erb',
        datadir       => '/srv/labsdb/data',
        basedir       => $profile::mariadb::packages_wmf::basedir,
        tmpdir        => '/srv/labsdb/tmp',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
        read_only     => 'OFF',
        socket        => $socket,
    }
}
