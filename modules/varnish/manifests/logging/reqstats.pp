# == Define varnish::logging::reqstats:
# Installs a Diamond collector that sends varnish request stats to statsd/graphite.
#
# === Parameters
# [*instance_name*]
#   Name of the varnish instance from which to gather request stats.
#   Default: $name.
#
# [*interval*]
#   Send counters to statsd every $interval seconds.  Default 60
#
# [*statsd*]
#   StatsD server address, in "host:port" format.
#   Defaults to localhost:8125
#
# [*metric_prefix*]
#   Prefix of the stats that will be sent to statsd.
#   Default: varnish.$site.$name.request.
#   If $name is text.frontend,  this will create graphite keys that look like:
#   servers.cp1052.varnish.eqiad.text.frontend.request.client.status.2xx
#
define varnish::logging::reqstats(
    $instance_name = $name,
    $interval      = 60,
    $statsd        = 'localhost:8125',
    $metric_prefix = "varnish.${::site}.${name}.request",
    $ensure        = 'present',
) {
    if $instance_name != '' {
        $service_unit_name = "varnishreqstats-${instance_name}"
        $varnish_service_name = "varnish-${instance_name}"
    } else {
        $service_unit_name = 'varnishreqstats-default'
        $varnish_service_name = 'varnish'
    }

    if ! defined(File['/usr/local/bin/varnishreqstats']) {
        file { '/usr/local/bin/varnishreqstats':
            source  => 'puppet:///modules/varnish/varnishreqstats',
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            require => File['/usr/local/lib/python2.7/dist-packages/varnishlog.py'],
            notify  => Service[$service_unit_name],
        }
    }

    base::service_unit { $service_unit_name:
        ensure         => $ensure,
        systemd        => true,
        strict         => false,
        template_name  => 'varnishreqstats',
        require        => File['/usr/local/bin/varnishreqstats'],
        service_params => {
            require => Service[$varnish_service_name],
            enable => true,
        },
    }
}
