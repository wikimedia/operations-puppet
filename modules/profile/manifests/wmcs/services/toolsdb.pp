# SPDX-License-Identifier: Apache-2.0
# = Class: profile::wmcs::services::toolsdb
class profile::wmcs::services::toolsdb (
    Stdlib::Unixpath $socket = lookup('profile::wmcs::services::toolsdb::socket', {default_value => '/var/run/mysqld/mysqld.sock'}),
    Stdlib::Fqdn $primary_server = lookup('profile::wmcs::services::toolsdb::primary_server'),
    Boolean $rebuild = lookup('profile::wmcs::services::toolsdb::rebuild', {default_value => false}),
) {
    require profile::wmcs::services::toolsdb_apt_pinning

    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    class { '::mariadb::service':
      # Use jemalloc to prevent memory issues (T353093)
      override => '[Service]\nEnvironment="LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2"',
    }

    class { 'profile::mariadb::monitor::prometheus':
        socket => $socket,
    }

    # This should depend on labs_lvm::srv but the /srv/ vols were hand built
    # on the first two toolsdb VMs to exactly match the physical servers.
    # New ones should directly use that profile so we can add it here.
    file { '/srv/labsdb':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/srv/labsdb/binlogs':
        ensure => directory,
        mode   => '0755',
        owner  => 'mysql',
        group  => 'mysql',
    }

    $config_file_template = 'role/mariadb/mysqld_config/tools.my.cnf.erb'

    class { 'mariadb::config':
        config        => $config_file_template,
        datadir       => '/srv/labsdb/data',
        tmpdir        => '/srv/labsdb/tmp',
        basedir       => $profile::mariadb::packages_wmf::basedir,
        read_only     => 'ON',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
        socket        => $socket,
    }

    class { 'mariadb::heartbeat':
        datacenter => $::site,
        enabled    => $primary_server == $::facts['networking']['fqdn'],
        shard      => 'toolsdb',
    }
}
