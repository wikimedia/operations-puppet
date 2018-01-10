# This instantiates testreduce::client
class role::parsoid::rt_client {
    include ::testreduce

    testreduce::client { 'parsoid-rt-client':
        instance_name => 'parsoid-rt-client',
        parsoid_port  => hiera('parsoid::testing::parsoid_port'),
    }
}
