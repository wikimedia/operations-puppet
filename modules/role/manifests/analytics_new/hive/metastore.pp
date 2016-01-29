# == Class role::analytics::hive::metastore
# Sets up Hive Metastore service
#
class role::analytics_new::hive::metastore {
    system::role { 'role::analytics::hive::metastore':
        description => 'hive-metastore service',
    }
    require role::analytics_new::hive::client

    # Setup hive-metastore
    class { 'cdh::hive::metastore': }

    ferm::service{ 'hive_metastore':
        proto  => 'tcp',
        port   => '9083',
        srange => '$INTERNAL',
    }
}