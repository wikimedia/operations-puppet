# == Class: profile::thanos::query_frontend
#
# Configure the Thanos query-frontend component.
# Memcached is supported, and shared with Swift (frontend)

class profile::thanos::query_frontend (
    Array $prometheus_nodes = lookup('prometheus_nodes'),
    Array[Stdlib::Host] $memcached_hosts = lookup('profile::thanos::query_frontend::memcached_hosts'),
) {
    $http_port = 16902

    class { 'thanos::query_frontend':
        http_port       => $http_port,
        memcached_hosts => $memcached_hosts,
        memcached_port  => 11211,
    }

    # Allow access only to query_frontend to scrape metrics
    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
    ferm::service { 'thanos_query_frontend_prometheus':
        proto  => 'tcp',
        port   => $http_port,
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }
}
