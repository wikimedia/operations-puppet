# == Class: profile::thanos::query
#
# Thanos query exposes a Prometheus-compatible query API over HTTP. Results are
# gathered from all configured Thanos StoreAPI endpoints.
#
# The endpoints are discovered via PuppetDB, using the same mechanism as
# Prometheus itself.
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

    $sites.each |String $s| {
        prometheus::resource_config{ "thanos_store_sidecar_${s}":
            dest           => "${sd_files_path}/sidecar_${s}.yml",
            site           => $s,
            define_name    => 'thanos::sidecar',
            port_parameter => 'grpc_port',
        }
    }

    ferm::service { 'thanos_query':
        proto  => 'tcp',
        port   => $http_port,
        srange => '$DOMAIN_NETWORKS',
    }
}
