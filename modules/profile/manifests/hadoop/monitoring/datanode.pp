# Class: profile::hadoop::monitoring::datanode
#
# Sets up Prometheus based monitoring for the Hadoop HDFS Datanode
#
class profile::hadoop::monitoring::datanode(
    $prometheus_nodes        = hiera('prometheus_nodes'),
) {
    $jmx_exporter_config_file = '/etc/hadoop/prometheus_hdfs_datanode_jmx_exporter.yaml'
    $prometheus_jmx_exporter_datanode_port = 51010
    $java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_datanode_port}:${jmx_exporter_config_file}"
    profile::prometheus::jmx_exporter { "hdfs_datanode_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_datanode_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        source           => 'puppet:///modules/profile/hadoop/prometheus_hdfs_datanode_jmx_exporter.yaml',
    }
}