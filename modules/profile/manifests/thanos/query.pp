# SPDX-License-Identifier: Apache-2.0
# == Class: profile::thanos::query
#
# Thanos query exposes a Prometheus-compatible query API over HTTP. Results are
# gathered from all configured Thanos StoreAPI endpoints.
#
# The sidecars are discovered via PuppetDB, using the same mechanism as
# Prometheus itself. For historical data the local Thanos Store will be used.
#
# = Parameters
# [*sites*] The list of sites to reach out to.
# [*rule_hosts*] The thanos rule configuration. See thanos::query for details.

class profile::thanos::query (
    Array[String] $sites = lookup('datacenters'),
    Hash[String, Hash] $rule_hosts = lookup('profile::thanos::rule_hosts'),
) {
    $sd_files = '/etc/thanos-query/stores/*.yml'
    $sd_files_path = dirname($sd_files)
    $http_port = 10902

    class { 'thanos::query':
        http_port       => $http_port,
        sd_files        => $sd_files,
        tracing_enabled => true,
    }

    # Reach out to all sites' sidecars for recent data
    $sites.each |String $s| {
        prometheus::resource_config{ "thanos_store_sidecar_${s}":
            dest            => "${sd_files_path}/sidecar_${s}.yml",
            prometheus_site => $s,
            define_name     => 'thanos::sidecar',
            port_parameter  => 'grpc_port',
        }
    }

    # Reach out to rule component for recording rules
    $rule_targets = [ { 'targets' => $rule_hosts.keys.map |$h| { "${h}:17901" } } ]
    file { "${sd_files_path}/rule.yml":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => to_yaml($rule_targets),
    }

    # Talk to local store for historical data
    $local_store = [ { 'targets' => ['localhost:11901'] } ]
    file { "${sd_files_path}/local.yml":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => to_yaml($local_store),
    }

    ferm::service { 'thanos_query':
        proto  => 'tcp',
        port   => $http_port,
        srange => '$DOMAIN_NETWORKS',
    }
}
