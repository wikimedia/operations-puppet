# This instantiates testreduce::client for visual diff testing
class role::parsoid-vd-client {
    # FIXME Are these includes required?
    # All I want to do is ensure that these repositories are initialized
    include ::testreduce
    include ::visualdiff

    testreduce::client { 'parsoid-vd-client':
        instance_name => 'parsoid-vd-client',
    }
}
