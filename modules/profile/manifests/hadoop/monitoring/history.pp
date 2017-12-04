# Class: profile::hadoop::monitoring::history
#
# Sets up Prometheus based monitoring for the Hadoop MapReduce History server
#
class profile::hadoop::monitoring::history(
    $prometheus_nodes        = hiera('prometheus_nodes'),
) {
    $jmx_exporter_config_file = '/etc/hadoop/prometheus_mapreduce_history_jmx_exporter.yaml'
    $prometheus_jmx_exporter_history_port = 10086
    $java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_history_port}:${jmx_exporter_config_file}"
    profile::prometheus::jmx_exporter { "mapreduce_history_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_history_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        source           => 'puppet:///modules/profile/hadoop/prometheus_mapreduce_history_jmx_exporter.yaml',
    }
}