# Class: profile::druid::monitoring::coordinator
#
# Sets up Prometheus based monitoring (only jvm) for the druid coordinator.
#
class profile::druid::monitoring::coordinator(
    $prometheus_nodes        = hiera('prometheus_nodes'),
) {
    $jmx_exporter_config_file = '/etc/druid/jvm_prometheus_jmx_exporter.yaml'
    $prometheus_jmx_exporter_coordinator_port = 8181
    $java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_coordinator_port}:${jmx_exporter_config_file}"
    profile::prometheus::jmx_exporter { "druid_coordinator_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_coordinator_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        source           => 'puppet:///modules/profile/druid/jvm_prometheus_jmx_exporter.yaml',
    }
}