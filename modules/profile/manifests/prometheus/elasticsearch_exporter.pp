# SPDX-License-Identifier: Apache-2.0
# == Define: profile::prometheus::elasticsearch_exporter
#
# Configures a prometheus elasticsearch exporter and sets up appropriate
# firewall rules for collection from the exporter.
#
# == Parameters
#
# [*prometheus_port*]
#   Port used by the exporter for the listen socket
# [*elasticsearch_host*]
#   The host running elasticsearch
# [*elasticsearch_port*]
#   Port to monitor elasticsearch on
# [*elasticsearch_scheme*]
#   The URL scheme to access elasticsearch
# [*elasticsearch_ca*]
#   The certificate authority backing the elasticsearch https endpoint
# [*extra_config*]
#   Additional configuration settings.
#   c.f. https://github.com/prometheus-community/elasticsearch_exporter?tab=readme-ov-file#configuration
#
define profile::prometheus::elasticsearch_exporter(
    Stdlib::Port          $prometheus_port,
    Stdlib::Host          $elasticsearch_host,
    Stdlib::Port          $elasticsearch_port,
    Enum['http', 'https'] $elasticsearch_scheme,
    Optional[String]      $elasticsearch_ca,
    String                $extra_config = '',
) {
    $extra_config_real = $elasticsearch_ca ? {
        undef   => $extra_config,
        default => "--es.ca=${elasticsearch_ca} ${extra_config}"
    }

    prometheus::elasticsearch_exporter { "${elasticsearch_host}:${elasticsearch_port}":
        elasticsearch_host   => $elasticsearch_host,
        elasticsearch_port   => $elasticsearch_port,
        elasticsearch_scheme => $elasticsearch_scheme,
        prometheus_port      => $prometheus_port,
        extra_config         => $extra_config_real
    }
}
