# Temporary storage class, very similar to core, but without
# monitoring and other production-y things. This is mostly
# for es2001-4 hosts, which keep a mysql install, but are
# mostly used for temporary storage when disk space is needed
class role::mariadb::temporary_storage {
    if os_version('debian >= stretch') {
        $default_package = 'wmf-mariadb101'
    } else {
        $default_package = 'wmf-mariadb10'
    }
    $package = hiera('mariadb::package', $default_package)
    $basedir = hiera('mariadb::basedir',  "/opt/${package}")
    $socket = hiera('mariadb::socket', '/run/mysqld/mysqld.sock')
    $datadir = hiera('mariadb::datadir', '/srv/sqldata')
    $tmpdir = hiera('mariadb::tmpdir', '/srv/tmp')
    $mysql_role = 'standalone'
    $semi_sync = 'off'
    $ssl = 'puppet-cert'
    $binlog_format = hiera('mariadb::binlog_format', 'ROW')

    system::role { 'mariadb::temporary_storage':
        description => 'MariaDB temporary storage',
    }

    include ::profile::standard
    include ::profile::base::firewall
    # mariadb port not open to the world (change for remote managing)
    # include ::role::mariadb::ferm

    class {'mariadb::packages_wmf':
        package => $package,
    }
    class {'mariadb::service':
        package  => $package,
    }

    class { 'mariadb::config':
        config           => 'role/mariadb/mysqld_config/production.my.cnf.erb',
        basedir          => $basedir,
        datadir          => $datadir,
        tmpdir           => $tmpdir,
        socket           => $socket,
        p_s              => 'on',
        ssl              => $ssl,
        binlog_format    => $binlog_format,
        semi_sync        => $semi_sync,
        replication_role => $mysql_role,
    }
}
