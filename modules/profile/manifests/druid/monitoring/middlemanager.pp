# Class: profile::druid::monitoring::middlemanager
#
# Sets up Prometheus based monitoring (only jvm) for the druid middle manager.
#
class profile::druid::monitoring::middlemanager(
    $prometheus_nodes        = hiera('prometheus_nodes'),
) {
    $jmx_exporter_config_file = '/etc/druid/jvm_prometheus_middlemanager_jmx_exporter.yaml'
    $prometheus_jmx_exporter_middlemanager_port = 8191
    $java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_middlemanager_port}:${jmx_exporter_config_file}"
    profile::prometheus::jmx_exporter { "druid_middlemanager_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_middlemanager_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        source           => 'puppet:///modules/profile/druid/jvm_prometheus_jmx_exporter.yaml',
    }
}