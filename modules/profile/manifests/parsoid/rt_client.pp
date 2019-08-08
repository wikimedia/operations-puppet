# This instantiates testreduce::client
class profile::parsoid::rt_client(
    $parsoid_port = hiera('parsoid::testing::parsoid_port'),
    $use_parsoid_php = hiera('parsoid::testing::use_parsoid_php'),
){
    include ::testreduce

    testreduce::client { 'parsoid-rt-client':
        instance_name   => 'parsoid-rt-client',
        parsoid_port    => $parsoid_port,
        use_parsoid_php => $use_parsoid_php
    }

    base::service_auto_restart { 'parsoid-rt-client': }
}
