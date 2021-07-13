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

class profile::thanos::query (
    $sites = lookup('datacenters'),
) {
    $sd_files = '/etc/thanos-query/stores/*.yml'
    $sd_files_path = dirname($sd_files)
    $http_port = 10902

    class { 'thanos::query':
        http_port => $http_port,
        sd_files  => $sd_files,
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

    # Talk to local store for historical data
    $local_store = [ { 'targets' =>  ['localhost:11901'] } ]
    file { "${sd_files_path}/local.yml":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => ordered_yaml($local_store),
    }

    ferm::service { 'thanos_query':
        proto  => 'tcp',
        port   => $http_port,
        srange => '$DOMAIN_NETWORKS',
    }
}
