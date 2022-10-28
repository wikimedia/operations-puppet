# SPDX-License-Identifier: Apache-2.0
# This instantiates testreduce::client for visual diff testing
class profile::parsoid::vd_client (
    Stdlib::Port $parsoid_port = lookup('parsoid::testing::parsoid_port'),
    Stdlib::Ensure::Service $service_ensure = lookup('profile::parsoid::vd_client::service_ensure'),
) {

    include ::visualdiff

    testreduce::client { 'parsoid-vd-client':
        instance_name  => 'parsoid-vd-client',
        service_ensure => $service_ensure,
        parsoid_port   => $parsoid_port,
    }

    profile::auto_restarts::service { 'parsoid-vd-client': }
}
