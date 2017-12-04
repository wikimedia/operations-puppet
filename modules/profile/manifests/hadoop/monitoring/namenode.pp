# Class: profile::hadoop::monitoring::namenode
#
# Sets up Prometheus based monitoring for the Hadoop HDFS Namenode
#
class profile::hadoop::monitoring::namenode(
    $prometheus_nodes        = hiera('prometheus_nodes'),
) {
    $jmx_exporter_config_file = '/etc/hadoop/prometheus_hdfs_namenode_jmx_exporter.yaml'
    $prometheus_jmx_exporter_namenode_port = 10080
    $java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_namenode_port}:${jmx_exporter_config_file}"
    profile::prometheus::jmx_exporter { "hdfs_namenode_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_namenode_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        source           => 'puppet:///modules/profile/hadoop/prometheus_hdfs_namenode_jmx_exporter.yaml',
    }
}