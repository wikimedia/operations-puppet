# SPDX-License-Identifier: Apache-2.0
# == Define: profile::prometheus::wmf_elasticsearch_exporter
#
# This adds some WMF specific metrics that are not available in the standard exporter.
#
# == Parameters
#
# [*prometheus_port*]
#   Port used by the exporter for the listen socket
# [*elasticsearch_port*]
#   Port to monitor elasticsearch on
# [*indices_to_monitor*]
#   Array of elasticsearch indices or aliases to track metrics for
#
define profile::prometheus::wmf_elasticsearch_exporter(
    Stdlib::Port $prometheus_port,
    Stdlib::Port $elasticsearch_port,
    Array[String] $indices_to_monitor,
){

    prometheus::wmf_elasticsearch_exporter { $title:
        prometheus_port    => $prometheus_port,
        elasticsearch_port => $elasticsearch_port,
        indices_to_monitor => $indices_to_monitor,
    }
}
