# SPDX-License-Identifier: Apache-2.0

define prometheus::prometheus_cardinality_exporter (
    Stdlib::Port    $exporter_port,
    Stdlib::HTTPUrl $prometheus_url,
    Float           $polling_interval,
    Wmflib::Ensure  $ensure = present,
) {

    ensure_packages('prometheus-cardinality-exporter', {
        ensure => $ensure,
    })

    file { "/etc/default/prometheus-cardinality-exporter@${title}.conf":
        ensure  => stdlib::ensure($ensure, 'file'),
        mode    => '0444',
        content => epp('prometheus/prometheus_cardinality_exporter_instance.conf.epp', {
            'proms' => $prometheus_url,
            'port'  => $exporter_port,
            'freq'  => $polling_interval,
        }),
        require => [
            Package['prometheus-cardinality-exporter'],
        ]
    }

    $service_enable = $ensure ? {
        present => true,
        absent => false,
    }

    service { "prometheus-cardinality-exporter@${title}":
        ensure    => stdlib::ensure($ensure, 'service'),
        enable    => $service_enable,
        require   => [
            File["/etc/default/prometheus-cardinality-exporter@${title}.conf"]
        ],
        subscribe => [
            File["/etc/default/prometheus-cardinality-exporter@${title}.conf"]
        ],
    }

    profile::auto_restarts::service { "prometheus-cardinality-exporter@${title}":
        ensure  => $ensure,
        require => [
            Service["prometheus-cardinality-exporter@${title}"],
        ],
    }

}
