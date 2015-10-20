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
    $ensure        = 'present',
) {
    # ${collector_name}Collector will be used as the python diamond collector class name
    # when varnishreqstats-diamond.py.erb is rendered.
    $collector_name = "Varnishreqstats${name}"
    diamond::collector { $collector_name:
        ensure   => $ensure,
        content  => template('varnish/varnishreqstats-diamond.py.erb'),
        settings => {
            'varnish_name' => $instance_name,
            'path'         => $metric_path,
        },
    }
}
