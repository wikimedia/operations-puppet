# Class: profile::hadoop::monitoring::nodemanager
#
# Sets up Prometheus based monitoring for the Hadoop NodeManager
#
class profile::hadoop::monitoring::nodemanager(
    $prometheus_nodes        = hiera('prometheus_nodes'),
) {
    $jmx_exporter_config_file = '/etc/hadoop/prometheus_yarn_nodemanager_jmx_exporter.yaml'
    $prometheus_jmx_exporter_nodemanager_port = 8141
    $java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_nodemanager_port}:${jmx_exporter_config_file}"
    profile::prometheus::jmx_exporter { "yarn_nodemanager_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_nodemanager_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        source           => 'puppet:///modules/profile/hadoop/prometheus_yarn_nodemanager_jmx_exporter.yaml',
    }
}