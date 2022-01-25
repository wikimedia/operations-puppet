# Class: profile::presto::monitoring::server
#
# Sets up Prometheus based monitoring for the Presto Server.
#
class profile::presto::monitoring::server {
    $jmx_exporter_config_file = '/etc/prometheus/presto_server_jmx_exporter.yaml'
    $prometheus_jmx_exporter_server_port = 10281
    $java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_server_port}:${jmx_exporter_config_file}"
    profile::prometheus::jmx_exporter { "presto_server_${::hostname}":
        hostname    => $::hostname,
        port        => $prometheus_jmx_exporter_server_port,
        config_file => $jmx_exporter_config_file,
        config_dir  => '/etc/prometheus',
        source      => 'puppet:///modules/profile/presto/monitoring/prometheus_jmx_exporter.yaml',
    }
}
