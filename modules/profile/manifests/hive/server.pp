# == Class profile::hive::server
#
# Sets up Hive Server2 (no metastore, needs another profile).
#
class profile::hive::server(
    $monitoring_enabled  = hiera('profile::hive::server::monitoring_enabled', false),
    $ferm_srange         = hiera('profile::hive::server::ferm_srange', '$DOMAIN_NETWORKS'),
    $use_kerberos        = hiera('profile::hive::server::use_kerberos', false),
) {
    include ::profile::hive::client

    # Setup hive-server
    class { '::cdh::hive::server':
        use_kerberos => $use_kerberos,
    }

    ferm::service{ 'hive_server':
        proto  => 'tcp',
        port   => '10000',
        srange => $ferm_srange,
    }

    # Include icinga alerts if production realm.
    if $monitoring_enabled {
        include ::profile::hive::monitoring::server

        nrpe::monitor_service { 'hive-server2':
            description   => 'Hive Server',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hive.service.server.HiveServer2"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hive::server'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hive',
        }

        monitoring::check_prometheus { 'hive-server-heap-usage':
            description     => 'Hive Server JVM Heap usage',
            dashboard_links => ['https://grafana.wikimedia.org/d/000000379/hive?panelId=7&fullscreen&orgId=1'],
            query           => "scalar(avg_over_time(jvm_memory_bytes_used{instance=\"${::hostname}:10100\",area=\"heap\"}[60m])/avg_over_time(jvm_memory_bytes_max{instance=\"${::hostname}:10100\",area=\"heap\"}[60m]))",
            warning         => 0.8,
            critical        => 0.9,
            contact_group   => 'analytics',
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
        }
    }
}
