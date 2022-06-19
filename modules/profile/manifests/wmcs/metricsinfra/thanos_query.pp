# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::metricsinfra::thanos_query (
    Array[Stdlib::Fqdn] $prometheus_hosts = lookup('profile::wmcs::metricsinfra::prometheus_hosts'),
) {
    $sd_files = '/etc/thanos-query/stores/*.yml'
    $sd_files_path = dirname($sd_files)
    $http_port = 10902

    class { 'thanos::query':
        http_port => $http_port,
        sd_files  => $sd_files,
    }

    $prometheus_targets = [ { 'targets' => $prometheus_hosts.map |$h| { "${h}:29900" } } ]
    file { "${sd_files_path}/prometheus.yml":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => to_yaml($prometheus_targets),
    }
}
