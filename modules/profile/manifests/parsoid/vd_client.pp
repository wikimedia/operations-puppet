# This instantiates testreduce::client for visual diff testing
class profile::parsoid::vd_client (
    $parsoid_port = hiera('parsoid::testing::parsoid_port'),
    $use_parsoid_php = hiera('parsoid::testing::use_parsoid_php'),
) {
    include ::testreduce
    include ::visualdiff

    testreduce::client { 'parsoid-vd-client':
        instance_name   => 'parsoid-vd-client',
        parsoid_port    => $parsoid_port,
        use_parsoid_php => $use_parsoid_php,
    }

    base::service_auto_restart { 'parsoid-vd-client': }
}
