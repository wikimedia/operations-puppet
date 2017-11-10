# Class: profile::druid::monitoring
#
# Sets up Prometheus based monitoring for all the druid workers. This assumes
# that all the Druid workers are running all the daemons.
#
class profile::druid::broker::monitoring (
    $prometheus_nodes        = hiera('prometheus_nodes'),
) {
    $jmx_exporter_config_file = '/etc/druid/jvm_prometheus_jmx_exporter.yaml'
    $prometheus_jmx_exporter_broker_port = 8182
    $broker_extra_java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_broker_port}:${jmx_exporter_config_file}"
    profile::prometheus::jmx_exporter { "druid_broker_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_broker_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        source           => 'puppet:///modules/profile/druid/jvm_prometheus_jmx_exporter.yaml',
    }
}