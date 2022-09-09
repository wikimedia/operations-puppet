# SPDX-License-Identifier: Apache-2.0
# Class: profile::druid::monitoring::broker
#
# Sets up Prometheus based monitoring (only jvm) for the druid broker.
#
class profile::druid::monitoring::broker {
    $jmx_exporter_config_file = '/etc/prometheus/druid_broker_jmx_exporter.yaml'
    $prometheus_jmx_exporter_broker_port = 8182
    $java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_broker_port}:${jmx_exporter_config_file}"
    profile::prometheus::jmx_exporter { "druid_broker_${::hostname}":
        hostname    => $::hostname,
        port        => $prometheus_jmx_exporter_broker_port,
        config_file => $jmx_exporter_config_file,
        config_dir  => '/etc/prometheus',
        source      => 'puppet:///modules/profile/druid/jvm_prometheus_jmx_exporter.yaml',
    }
}
