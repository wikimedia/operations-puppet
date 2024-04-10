# SPDX-License-Identifier: Apache-2.0
# == Class: profile::matomo::database
#
# Set up a simple mysql database for Matomo.

class profile::matomo::database (
    Stdlib::Port $database_port       = lookup('profile::matomo::database', { 'default_value' => 3306 }),
    Array[Stdlib::Host] $backup_hosts = lookup('profile::matomo::database::backup_hosts', { 'default_value' => undef }),
) {
    package { 'mysql-server':
        ensure => absent,
    }

    $mariadb_socket = '/run/mysqld/mysqld.sock'

    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    include profile::mariadb::monitor::prometheus

    class { 'mariadb::config':
        config    => 'profile/matomo/my.cnf.erb',
        socket    => $mariadb_socket,
        port      => $database_port ,
        datadir   => '/var/lib/mysql',
        basedir   => $profile::mariadb::packages_wmf::basedir,
        read_only => false,
        ssl       => 'puppet-cert',
    }

    class { 'mariadb::service':
        ensure  => 'running',
        manage  => true,
        enable  => true,
        require => Class['mariadb::config'],
    }

    if $backup_hosts {
        firewall::service { 'mariadb':
            proto  => 'tcp',
            port   => $database_port,
            srange => $backup_hosts,
        }
    }
}
