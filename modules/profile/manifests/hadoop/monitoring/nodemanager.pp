# Class: profile::hadoop::monitoring::nodemanager
#
# Sets up Prometheus based monitoring for the Hadoop NodeManager.
# This profile takes care of installing the Prometheus exporter and setting
# up its configuration file, but it does not instruct the target JVM to use it.
#
class profile::hadoop::monitoring::nodemanager(
    $prometheus_nodes        = hiera('prometheus_nodes'),
    $hadoop_cluster_name     = hiera('profile::hadoop::common::hadoop_cluster_name'),
) {
    $jmx_exporter_config_file = '/etc/prometheus/yarn_nodemanager_jmx_exporter.yaml'
    $prometheus_jmx_exporter_nodemanager_port = 8141
    profile::prometheus::jmx_exporter { "yarn_nodemanager_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_nodemanager_port,
        prometheus_nodes => $prometheus_nodes,
        # Label these metrics with the hadoop cluster name.
        labels           => { 'hadoop_cluster' => $hadoop_cluster_name },
        config_file      => $jmx_exporter_config_file,
        config_dir       => '/etc/prometheus',
        source           => 'puppet:///modules/profile/hadoop/prometheus_yarn_nodemanager_jmx_exporter.yaml',
    }
}
