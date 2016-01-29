# == Class role::analytics::hive::server
# Sets up Hive Server2
#
class role::analytics_new::hive::server {
    system::role { 'role::analytics::hive::server':
        description => 'hive-server2 service',
    }
    require role::analytics_new::hive::client

    # Setup hive-server
    class { 'cdh::hive::server': }

    ferm::service{ 'hive_server':
        proto  => 'tcp',
        port   => '10000',
        srange => '$INTERNAL',
    }

}