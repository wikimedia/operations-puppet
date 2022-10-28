# SPDX-License-Identifier: Apache-2.0
# This instantiates testreduce::client
class profile::parsoid::rt_client(
    Stdlib::Port $parsoid_port = lookup('parsoid::testing::parsoid_port'),
    Stdlib::Ensure::Service $service_ensure = lookup('profile::parsoid::rt_client::service_ensure'),
){

    testreduce::client { 'parsoid-rt-client':
        instance_name  => 'parsoid-rt-client',
        service_ensure => $service_ensure,
        parsoid_port   => $parsoid_port,
    }

    profile::auto_restarts::service { 'parsoid-rt-client': }
}
