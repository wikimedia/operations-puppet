# This instantiates testreduce::client for visual diff testing
class profile::parsoid::vd_client (
    $parsoid_port = hiera('parsoid::testing::parsoid_port'),
    Stdlib::Ensure::Service $service_ensure = lookup('profile::parsoid::vd_client::service_ensure'),
) {
    include ::testreduce
    include ::visualdiff

    testreduce::client { 'parsoid-vd-client':
        instance_name  => 'parsoid-vd-client',
        service_ensure => $service_ensure,
        parsoid_port   => $parsoid_port,
    }

    base::service_auto_restart { 'parsoid-vd-client': }
}
