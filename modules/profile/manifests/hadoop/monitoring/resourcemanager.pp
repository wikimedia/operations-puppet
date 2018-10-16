# Class: profile::hadoop::monitoring::resourcemanager
#
# Sets up Prometheus based monitoring for the Hadoop Yarn Resourcemanager.
# This profile takes care of installing the Prometheus exporter and setting
# up its configuration file, but it does not instruct the target JVM to use it.
#
class profile::hadoop::monitoring::resourcemanager(
    $prometheus_nodes        = hiera('prometheus_nodes'),
    $hadoop_cluster_name     = hiera('profile::hadoop::common::hadoop_cluster_name'),
) {
    $jmx_exporter_config_file = '/etc/prometheus/yarn_resourcemanager_jmx_exporter.yaml'
    $prometheus_jmx_exporter_resourcemanager_port = 10083
    profile::prometheus::jmx_exporter { "hdfs_datanode_${::hostname}":
        hostname         => $::hostname,
        # Label these metrics with the hadoop cluster name.
        labels           => { 'hadoop_cluster' => $hadoop_cluster_name },
        port             => $prometheus_jmx_exporter_resourcemanager_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        config_dir       => '/etc/prometheus',
        source           => 'puppet:///modules/profile/hadoop/prometheus_yarn_resourcemanager_jmx_exporter.yaml',
    }
}
