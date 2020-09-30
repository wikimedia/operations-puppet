# Class: profile::zookeeper::monitoring::server
#
# Sets up Prometheus based monitoring (only jvm) for the zookeeperd server.
#
class profile::zookeeper::monitoring::server(
    String $cluster_name = lookup('profile::zookeeper::cluster_name'),
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
){

    $jmx_exporter_config_file = '/etc/prometheus/jvm_zookeeper_jmx_exporter.yaml'
    $prometheus_jmx_exporter_zookeeper_server_port = 12181
    $java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_zookeeper_server_port}:${jmx_exporter_config_file}"
    profile::prometheus::jmx_exporter { "zookeeper_server_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_zookeeper_server_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        config_dir       => '/etc/prometheus',
        source           => 'puppet:///modules/profile/zookeeper/jvm_prometheus_jmx_exporter.yaml',
        labels           => {
            'zookeeper_cluster' => $cluster_name,
        },
    }
}
