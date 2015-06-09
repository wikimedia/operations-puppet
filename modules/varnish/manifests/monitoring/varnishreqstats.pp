# == Define varnish::monitoring::varnishreqstats:
# Installs a Diamond collector that sends varnish request stats to statsd/graphite.
#
# === Parameters
# [*instance_name*]
#   Name of the varnish instance from which to gather request stats.
#   Default: $name.
#
#
# [*metric_path*]
#   Prefix of the stats that will be sent to statsd/graphite.
#   Default: varnish.$site.$name.request.
#   If $name is text.frontend,  this will create graphite keys that look like:
#   servers.cp1052.varnish.eqiad.text.frontend.request.client.status.2xx
#
define varnish::monitoring::varnishreqstats(
    $instance_name = $name,
    $metric_path   = "varnish.${::site}.${name}.request",
) {
    diamond::collector { "varnishreqstats-${name}":
        source   => 'puppet:///modules/varnish/varnishreqstats-diamond.py',
        custom_name => 'varnishreqstats',
        settings => {
            'varnish_name' => $instance_name,
            'path'         => $metric_path,
        },
    }
}
