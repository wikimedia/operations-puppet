# == Class varnish::monitoring::varnishstats
# Installs a Diamond collector that sends varnish request stats to statsd/graphite.
#
define varnish::monitoring::varnishstats(
    $metric_path = "varnish.$::{site}.${name}.request",
) {
    diamond::collector { 'varnishstats':
        source   => 'puppet:///modules/varnish/varnishstats-diamond-collector.py',
        settings => {
            'varnishname' => $name,
            'path'        => $metric_path,
        },
    }
}
