# == Class role::analytics_cluster::hive::server
# Sets up Hive Server2
#
class role::analytics_cluster::hive::server {
    system::role { 'role::analytics_cluster::hive::server':
        description => 'hive-server2 service',
    }
    require role::analytics_cluster::hive::client

    # Setup hive-server
    class { 'cdh::hive::server': }

    ferm::service{ 'hive_server':
        proto  => 'tcp',
        port   => '10000',
        srange => '$INTERNAL',
    }

}