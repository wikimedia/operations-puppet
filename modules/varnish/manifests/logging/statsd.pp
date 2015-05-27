# == Define: varnish::logging::statsd
#
# Report backend response time averages and response status
# counts to StatsD.
#
# === Parameters
#
# [*instance_name*]
#   Varnish instance name. If not specified, monitor
#   the default instance.
#
# [*statsd_server*]
#   StatsD server address, in "host:port" format.
#   Defaults to localhost:8125.
#
# [*metric_prefix*]
#   A prefix to prepend to all metric names.
#   Defaults to "varnish.backends".
#
# === Examples
#
#  varnish::logging::statsd { 'frontend':
#    instance_name => 'frontend
#    statsd_server => 'statsd.eqiad.wmnet:8125
#    metric_prefix => 'varnish.backends',
#  }
#
define varnish::logging::statsd(
    $instance_name = '',
    $statsd_server = 'statsd',
    $metric_prefix = 'varnish.backends',
) {
    if $instance_name {
        $service_unit_name = "varnishstatsd-${instance_name}"
    } else {
        $service_unit_name = "varnishstatsd-default"
    }

    base::service_unit { $service_unit_name:
        ensure         => present,
        systemd        => true,
        strict         => false,
        template_name  => 'varnishstatsd',
        service_params => {
            enable => true,
        }
    }
}
