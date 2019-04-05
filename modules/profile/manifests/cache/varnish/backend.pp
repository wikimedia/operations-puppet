# == Class: profile::cache::varnish::backend
#
# Sets up the prometheus exporter for varnish backend on tcp/9131, as well as
# all logging-related services necessary on varnish backends.
#
# === Parameters
# [*statsd_host*] Statsd server hostname
#
# [*nodes*] List of prometheus nodes
#
class profile::cache::varnish::backend(
    $statsd_host = hiera('statsd'),
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    require ::profile::cache::base

    if $::realm == 'production' {
        # Periodic varnish backend cron restarts, we need this to mitigate
        # T145661
        class { 'cacheproxy::cron_restart':
            nodes         => $::profile::cache::base::nodes,
            cache_cluster => $::profile::cache::base::cache_cluster,
        }
    }

    class { 'varnish::logging::backend':
        statsd_host => $statsd_host,
    }

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    prometheus::varnish_exporter{ 'default': }

    ferm::service { 'prometheus-varnish-exporter':
        proto  => 'tcp',
        port   => '9131',
        srange => $ferm_srange,
    }
}
