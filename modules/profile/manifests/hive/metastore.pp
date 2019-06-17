# == Class profile::hive::metastore
#
# Sets up Hive Metastore service
#
class profile::hive::metastore(
    $monitoring_enabled = hiera('profile::hive::metastore::monitoring_enabled', false),
    $ferm_srange        = hiera('profile::hive::metastore::ferm_srange', '$DOMAIN_NETWORKS'),
) {

    require ::profile::hive::client

    # Setup hive-metastore
    class { '::cdh::hive::metastore': }

    ferm::service{ 'hive_metastore':
        proto  => 'tcp',
        port   => '9083',
        srange => $ferm_srange,
    }

    # Include icinga alerts if production realm.
    if $monitoring_enabled {
        require ::profile::hive::monitoring::metastore

        nrpe::monitor_service { 'hive-metasore':
            description   => 'Hive Metastore',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hive.metastore.HiveMetaStore"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hive::metastore'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hive',
        }

        monitoring::check_prometheus { 'hive-metastore-heap-usage':
            description     => 'Hive Metastore JVM Heap usage',
            dashboard_links => ['https://grafana.wikimedia.org/d/000000379/hive?panelId=2&fullscreen&orgId=1'],
            query           => "scalar(avg_over_time(jvm_memory_bytes_used{instance=\"${::hostname}:9183\",area=\"heap\"}[60m])/avg_over_time(jvm_memory_bytes_max{instance=\"${::hostname}:9183\",area=\"heap\"}[60m]))",
            warning         => 0.8,
            critical        => 0.9,
            contact_group   => 'analytics',
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
        }
    }
}
