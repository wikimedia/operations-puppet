# Class: profile::hadoop::monitoring::namenode
#
# Sets up Prometheus based monitoring for the Hadoop HDFS Namenode.
# This profile takes care of installing the Prometheus exporter and setting
# up its configuration file, but it does not instruct the target JVM to use it.
#
class profile::hadoop::monitoring::namenode(
    $prometheus_nodes        = hiera('prometheus_nodes'),
) {
    $jmx_exporter_config_file = '/etc/hadoop/prometheus_hdfs_namenode_jmx_exporter.yaml'
    $prometheus_jmx_exporter_namenode_port = 10080
    profile::prometheus::jmx_exporter { "hdfs_namenode_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_namenode_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        source           => 'puppet:///modules/profile/hadoop/prometheus_hdfs_namenode_jmx_exporter.yaml',
    }
}