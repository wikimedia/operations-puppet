# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::cadvisor (
    Wmflib::Ensure $ensure = lookup('profile::prometheus::cadvisor::ensure'),
    Array[Prometheus::Cadvisor::Metric] $metrics_enabled_extra = lookup('profile::prometheus::cadvisor::metrics_enabled_extra', {'default_value' => []}),
) {
    class { 'prometheus::cadvisor':
        port                  => 4194,
        ensure                => $ensure,
        metrics_enabled_extra => $metrics_enabled_extra,
    }
}
