# SPDX-License-Identifier: Apache-2.0
# Class: profile::druid::monitoring::coordinator
#
# Sets up Prometheus based monitoring (only jvm) for the druid coordinator.
#
class profile::druid::monitoring::coordinator {
    $jmx_exporter_config_file = '/etc/prometheus/druid_coordinator_jmx_exporter.yaml'
    $prometheus_jmx_exporter_coordinator_port = 8181
    $java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${facts['networking']['ip']}:${prometheus_jmx_exporter_coordinator_port}:${jmx_exporter_config_file}"
    profile::prometheus::jmx_exporter { "druid_coordinator_${facts['networking']['hostname']}":
        hostname    => $facts['networking']['hostname'],
        port        => $prometheus_jmx_exporter_coordinator_port,
        config_file => $jmx_exporter_config_file,
        config_dir  => '/etc/prometheus',
        source      => 'puppet:///modules/profile/druid/jvm_prometheus_jmx_exporter.yaml',
    }
}
