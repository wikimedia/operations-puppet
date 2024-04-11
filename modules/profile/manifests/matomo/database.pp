# SPDX-License-Identifier: Apache-2.0
# == Class: profile::matomo::database
#
# Set up a simple mysql database for Matomo.

class profile::matomo::database (
    Stdlib::Port $database_port       = lookup('profile::matomo::database', { 'default_value' => 3306 }),
    Stdlib::Unixpath $datadir         = lookup('profile::matomo::database::datadir', { 'default_value' => '/srv/sqldata' }),
    Stdlib::Unixpath $tmpdir          = lookup('profile::matomo::database::tmpdir', { 'default_value' => '/srv/tmp' }),
    Array[Stdlib::Host] $backup_hosts = lookup('profile::matomo::database::backup_hosts', { 'default_value' => undef }),
) {
    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    include profile::mariadb::monitor::prometheus

    $mariadb_socket = '/run/mysqld/mysqld.sock'

    class { 'mariadb::config':
        config    => 'profile/matomo/matomo.my.cnf.erb',
        socket    => $mariadb_socket,
        port      => $database_port ,
        datadir   => $datadir,
        tmpdir    => $tmpdir,
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
