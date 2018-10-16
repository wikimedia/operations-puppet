# Class: profile::hadoop::monitoring::namenode
#
# Sets up Prometheus based monitoring for the Hadoop HDFS Namenode.
# This profile takes care of installing the Prometheus exporter and setting
# up its configuration file, but it does not instruct the target JVM to use it.
#
class profile::hadoop::monitoring::namenode(
    $prometheus_nodes        = hiera('prometheus_nodes'),
    $hadoop_cluster_name     = hiera('profile::hadoop::common::hadoop_cluster_name'),
) {
    $jmx_exporter_config_file = '/etc/prometheus/hdfs_namenode_jmx_exporter.yaml'
    $prometheus_jmx_exporter_namenode_port = 10080
    profile::prometheus::jmx_exporter { "hdfs_namenode_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_namenode_port,
        prometheus_nodes => $prometheus_nodes,
        # Label these metrics with the hadoop cluster name.
        labels           => { 'hadoop_cluster' => $hadoop_cluster_name },
        config_file      => $jmx_exporter_config_file,
        config_dir       => '/etc/prometheus',
        source           => 'puppet:///modules/profile/hadoop/prometheus_hdfs_namenode_jmx_exporter.yaml',
    }
}
