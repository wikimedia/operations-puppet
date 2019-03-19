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
# [*key_prefix*]
#   A prefix to prepend to all metric names.
#   Defaults to "varnish.backends".
#
# === Examples
#
#  varnish::logging::statsd { 'frontend':
#    instance_name => 'frontend
#    statsd_server => 'statsd.eqiad.wmnet:8125
#    key_prefix    => 'varnish.backends',
#  }
#
define varnish::logging::statsd(
    $instance_name = '',
    $statsd_server = 'statsd',
    $key_prefix    = 'varnish.backends',
) {
    if $instance_name != '' {
        $service_unit_name = "varnishstatsd-${instance_name}"
    } else {
        $service_unit_name = 'varnishstatsd-default'
    }

    if ! defined(File['/usr/local/bin/varnishstatsd']) {
        file { '/usr/local/bin/varnishstatsd':
            source => 'puppet:///modules/varnish/varnishstatsd',
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            notify => Service[$service_unit_name],
        }
    }

    systemd::service { $service_unit_name:
        ensure         => present,
        content        => systemd_template('varnishstatsd'),
        require        => File['/usr/local/bin/varnishstatsd'],
        service_params => {
            enable => true,
        },
    }

    base::service_auto_restart { $service_unit_name: }

    nrpe::monitor_service { 'varnishstatsd':
        ensure       => present,
        description  => 'Varnish traffic logger - varnishstatsd',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -a "/usr/local/bin/varnishstatsd" -u root',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Varnish',
    }

    mtail::program { 'varnishbackend':
        source      => 'puppet:///modules/mtail/programs/varnishbackend.mtail',
        destination => '/etc/varnishmtail-backend',
        notify      => Service['varnishmtail-backend'],
    }
}
