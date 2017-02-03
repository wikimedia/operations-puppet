# == Class role::analytics_cluster::hive::metastore
# Sets up Hive Metastore service
#
# filtertags: labs-project-analytics labs-project-math
class role::analytics_cluster::hive::metastore {
    system::role { 'analytics_cluster::hive::metastore':
        description => 'hive-metastore service',
    }
    require ::role::analytics_cluster::hive::client

    # Setup hive-metastore
    class { '::cdh::hive::metastore': }

    ferm::service{ 'hive_metastore':
        proto  => 'tcp',
        port   => '9083',
        srange => '$ANALYTICS_NETWORKS',
    }

    # Include icinga alerts if production realm.
    if $::realm == 'production' {
        nrpe::monitor_service { 'hive-metasore':
            description   => 'Hive Metastore',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hive.metastore.HiveMetaStore"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hive::metastore'],
        }
    }
}
