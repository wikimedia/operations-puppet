# SPDX-License-Identifier: Apache-2.0
class prometheus::cadvisor(
    Wmflib::Ensure                      $ensure,
    Stdlib::Port                        $port,
    Array[Prometheus::Cadvisor::Metric] $metrics_enabled_extra = [],
    Stdlib::IP::Address                 $listen_address = $facts['wmflib']['is_container'] ? {
                                            true  => '0.0.0.0',
                                            false => $facts['networking']['ip'],
                                        },
) {
    # Taken by subtracting the default for -disable_metrics from the
    # list of all valid metrics
    $metrics_enabled_default = [
        'accelerator',
        'app',
        'cpu',
        'disk',
        'diskIO',
        'memory',
        'network',
        'oom_event',
        'perf_event',
    ]

    $metrics_enabled = assert_type(Array[Prometheus::Cadvisor::Metric],
        $metrics_enabled_default + $metrics_enabled_extra)

    package { 'cadvisor':
        ensure => $ensure,
    }

    systemd::service { 'cadvisor':
        ensure    => $ensure,
        content   => init_template('cadvisor', 'systemd_override'),
        override  => true,
        restart   => true,
        subscribe => Package['cadvisor'],
    }
}
