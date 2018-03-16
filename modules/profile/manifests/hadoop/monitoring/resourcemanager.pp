# Class: profile::hadoop::monitoring::resourcemanager
#
# Sets up Prometheus based monitoring for the Hadoop Yarn Resourcemanager.
# This profile takes care of installing the Prometheus exporter and setting
# up its configuration file, but it does not instruct the target JVM to use it.
#
class profile::hadoop::monitoring::resourcemanager(
    $prometheus_nodes        = hiera('prometheus_nodes'),
) {
    include ::profile::hadoop::common
    Class['cdh::hadoop'] -> Class['profile::hadoop::monitoring::resourcemanager']

    $jmx_exporter_config_file = '/etc/hadoop/prometheus_yarn_resourcemanager_jmx_exporter.yaml'
    $prometheus_jmx_exporter_resourcemanager_port = 10083
    profile::prometheus::jmx_exporter { "hdfs_datanode_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_resourcemanager_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        source           => 'puppet:///modules/profile/hadoop/prometheus_yarn_resourcemanager_jmx_exporter.yaml',
    }
}