# SPDX-License-Identifier: Apache-2.0
# Testreduce server for aggregating and displaying visualdiff results

# This instantiates testreduce::server
class profile::parsoid::vd_server(
    Stdlib::Ensure::Service $service_ensure = lookup('profile::parsoid::vd_server::service_ensure'),
){

    include ::passwords::testreduce::mysql

    testreduce::server { 'parsoid-vd':
        instance_name  => 'parsoid-vd',
        db_socket      => '/run/mysqld/mysqld.sock',
        db_host        => 'localhost',
        db_name        => 'testreduce_vd',
        db_user        => 'testreduce',
        db_pass        => $passwords::testreduce::mysql::db_pass,
        webapp_port    => 8010,
        coord_port     => 8011,
        service_ensure => $service_ensure,
    }

    profile::auto_restarts::service { 'parsoid-vd': }
}
