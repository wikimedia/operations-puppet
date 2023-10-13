# SPDX-License-Identifier: Apache-2.0
# Parsoid RT testing services

# This instantiates testreduce::server
class profile::parsoid::rt_server (
    Stdlib::Ensure::Service $service_ensure = lookup('profile::parsoid::rt_server::service_ensure'),
){

    include ::passwords::testreduce::mysql

    testreduce::server { 'parsoid-rt':
        instance_name  => 'parsoid-rt',
        db_socket      => '/run/mysqld/mysqld.sock',
        db_host        => 'localhost',
        db_name        => 'testreduce',
        db_user        => 'testreduce',
        db_pass        => $passwords::testreduce::mysql::db_pass,
        service_ensure => $service_ensure,
    }

    if debian::codename::ge('bookworm') {
        file { '/etc/mysql/mariadb.conf.d/50-testreduce-innodb.cnf':
            mode    => '0644',
            content => '[mysqld]\ninnodb_buffer_pool_size = 4.6G\n'
        }
    }

    profile::auto_restarts::service { 'parsoid-rt': }

    # mariadb only restarts on crashes by default (on-abort), make it
    # also restart for other failure modes:
    systemd::override { 'testreduce-mariadb-restart-on-failure':
        ensure  => present,
        unit    => 'mariadb',
        content => "[Service]\nRestart=always\n",
    }
}
