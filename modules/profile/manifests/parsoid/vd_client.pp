# This instantiates testreduce::client for visual diff testing
class profile::parsoid::vd_client {
    include ::testreduce
    include ::visualdiff

    testreduce::client { 'parsoid-vd-client':
        instance_name => 'parsoid-vd-client',
        parsoid_port  => hiera('parsoid::testing::parsoid_port'),
    }

    base::service_auto_restart { 'parsoid-vd-client': }
}
