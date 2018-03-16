# Class: profile::hadoop::monitoring::datanode
#
# Sets up Prometheus based monitoring for the Hadoop HDFS Datanode.
# This profile takes care of installing the Prometheus exporter and setting
# up its configuration file, but it does not instruct the target JVM to use it.
#
class profile::hadoop::monitoring::datanode(
    $prometheus_nodes        = hiera('prometheus_nodes'),
) {
    include ::profile::hadoop::common
    Class['cdh::hadoop'] -> Class['profile::hadoop::monitoring::datanode']

    $jmx_exporter_config_file = '/etc/hadoop/prometheus_hdfs_datanode_jmx_exporter.yaml'
    $prometheus_jmx_exporter_datanode_port = 51010
    profile::prometheus::jmx_exporter { "hdfs_datanode_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_datanode_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        source           => 'puppet:///modules/profile/hadoop/prometheus_hdfs_datanode_jmx_exporter.yaml',
    }
}