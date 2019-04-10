# == Class: profile::cache::varnish::backend
#
# Sets up a varnish cache backend. This includes:
#
# - storage configuration
# - prometheus exporter for varnish backend on tcp/9131
# - all logging-related services specific to varnish backends
#
# === Parameters
# [*storage_parts*]
#   Array of device names to be used by varnish-be.
#   For example: ['sda3', 'sdb3']
#
# [*statsd_host*]
#   Statsd server hostname
#
# [*nodes*]
#   List of prometheus nodes
#
class profile::cache::varnish::backend(
    $storage_parts = hiera('profile::cache::varnish::backend::storage_parts'),
    $statsd_host = hiera('statsd'),
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    require ::profile::cache::base

    ###########################################################################
    # Storage configuration
    ###########################################################################

    # Varnish backend storage/weight config

    $storage_size = $::hostname ? {
        /^cp1008$/                 => 117,  # Intel X-25M 160G (test host!)
        /^cp30(0[789]|10)$/        => 460,  # Intel M320 600G via H710 (esams misc)
        /^cp[45]0[0-9]{2}$/        => 730,  # Intel S3710 800G (ulsfo + eqsin)
        /^cp10(7[5-9]|8[0-9]|90)$/ => 1490, # Samsung PM1725a 1.6T (new eqiad nodes)
        /^cp[0-9]{4}$/             => 360,  # Intel S3700 400G (codfw, esams text/upload, legacy eqiad)
        default                    => 6,    # 6 is the bare min, for e.g. virtuals
    }

    $filesystems = unique($storage_parts)
    varnish::setup_filesystem { $filesystems: }
    Varnish::Setup_filesystem <| |> -> Varnish::Instance <| |>
    $file_storage_args = join($filesystems.map |$idx, $store| { "-s main${$idx + 1}=file,/srv/${store}/varnish.main${$idx + 1},${storage_size}G" }, ' ')

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
