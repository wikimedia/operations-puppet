# == Class role::analytics_cluster::hive::metastore
# Sets up Hive Metastore service
#
class role::analytics_cluster::hive::metastore {
    system::role { 'analytics_cluster::hive::metastore':
        description => 'hive-metastore service',
    }
    require role::analytics_cluster::hive::client

    # Setup hive-metastore
    class { 'cdh::hive::metastore': }

    ferm::service{ 'hive_metastore':
        proto  => 'tcp',
        port   => '9083',
        srange => '$INTERNAL',
    }
}
