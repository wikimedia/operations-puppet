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

    profile::auto_restarts::service { 'parsoid-rt': }
}
