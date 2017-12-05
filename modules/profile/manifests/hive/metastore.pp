# == Class profile::hive::metastore
#
# Sets up Hive Metastore service
#
class profile::hive::metastore(
    $monitoring_enabled = hiera('profile::hive::metastore::monitoring_enabled', false),
    $statsd             = hiera('statsd'),
) {

    require ::profile::hive::client

    # Setup hive-metastore
    class { '::cdh::hive::metastore': }

    # Use jmxtrans for sending metrics
    class { '::cdh::hive::jmxtrans::metastore':
        statsd  => $statsd,
    }

    ferm::service{ 'hive_metastore':
        proto  => 'tcp',
        port   => '9083',
        srange => '$ANALYTICS_NETWORKS',
    }

    # Include icinga alerts if production realm.
    if $monitoring_enabled {
        nrpe::monitor_service { 'hive-metasore':
            description   => 'Hive Metastore',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hive.metastore.HiveMetaStore"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hive::metastore'],
        }
    }
}
