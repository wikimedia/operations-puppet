# Class: profile::oozie::monitoring::server
#
# Sets up Prometheus based monitoring for the Oozie Server.
# This profile takes care of installing the Prometheus exporter and setting
# up its configuration file, but it does not instruct the target JVM to use it.
#
class profile::oozie::monitoring::server(
    $prometheus_nodes        = hiera('prometheus_nodes'),
) {
    $jmx_exporter_config_file = '/etc/oozie/prometheus_oozie_server_jmx_exporter.yaml'
    $prometheus_jmx_exporter_oozie_server_port = 12000
    profile::prometheus::jmx_exporter { "oozie_server_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_oozie_server_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        source           => 'puppet:///modules/profile/oozie/prometheus_oozie_server_jmx_exporter.yaml',
    }
}