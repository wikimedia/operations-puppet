# == Define: prometheus::druid_exporter
#
# Prometheus exporter for the Druid daemons.
#
# = Parameters
#
# [*arguments*]
#   Additional command line arguments for prometheus-druid-exporter.
#   The path to the metrics config file is already provided by default.
#   Default: ''
#
# [*druid_version*]
#   From version 0.8, the exporter supports the metric definition
#   via external json file. To simplify the overall configuration,
#   we define a list of supported/suggested metrics for each version
#   of Druid. In the future, if more granularity is needed, we may
#   add metric definition support via Hiera.
#   Default: '0.12.3'
#
define prometheus::druid_exporter (
    String $arguments = '',
    String $druid_version = '0.12.3',
) {
    package { 'prometheus-druid-exporter':
        ensure => present,
    }

    $metrics_config_file = '/etc/prometheus/druid-exporter_metrics'
    $metrics_config_version = regsubst($druid_version, '\.', '_', 'G')
    file { $metrics_config_file:
        ensure => present,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/prometheus/druid_exporter/metrics_config_${metrics_config_version}.json",
        notify => Service['prometheus-druid-exporter'],
    }

    file { '/etc/default/prometheus-druid-exporter':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "ARGS=\"${metrics_config_file} ${arguments}\"",
        notify  => Service['prometheus-druid-exporter'],
    }

    service { 'prometheus-druid-exporter':
        ensure  => running,
        require => [
            Package['prometheus-druid-exporter'],
            File['/etc/default/prometheus-druid-exporter'],
            File[$metrics_config_file]]
    }

    profile::auto_restarts::service { 'prometheus-druid-exporter': }
}
