# This instantiates testreduce::client for visual diff testing
class role::parsoid::vd_client {
    include ::testreduce
    include ::visualdiff

    testreduce::client { 'parsoid-vd-client':
        instance_name => 'parsoid-vd-client',
        service_state => stopped,
    }
}
