# This instantiates testreduce::client
class profile::parsoid::rt_client(
    $parsoid_port = hiera('parsoid::testing::parsoid_port'),
){
    include ::testreduce

    testreduce::client { 'parsoid-rt-client':
        instance_name => 'parsoid-rt-client',
        parsoid_port  => $parsoid_port,
    }

    base::service_auto_restart { 'parsoid-rt-client': }
}
