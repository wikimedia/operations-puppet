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
    if $instance_name {
        $service_unit_name = "varnishstatsd-${instance_name}"
    } else {
        $service_unit_name = 'varnishstatsd-default'
    }

    if (hiera('varnish_version4', false)) {
        # Use v4 version of varnishstatsd
        $varnish4_python_suffix = '4'
    } else {
        $varnish4_python_suffix = ''
    }

    if ! defined(File['/usr/local/bin/varnishstatsd']) {
        file { '/usr/local/bin/varnishstatsd':
            source  => "puppet:///modules/varnish/varnishstatsd${varnish4_python_suffix}",
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            require => File['/usr/local/lib/python2.7/dist-packages/varnishlog.py'],
            notify  => Service[$service_unit_name],
        }
    }

    base::service_unit { $service_unit_name:
        ensure         => present,
        systemd        => true,
        strict         => false,
        template_name  => 'varnishstatsd',
        require        => File['/usr/local/bin/varnishstatsd'],
        subscribe      => File['/usr/local/lib/python2.7/dist-packages/varnishlog.py'],
        service_params => {
            enable => true,
        },
    }

    nrpe::monitor_service { 'varnishstatsd':
        ensure       => present,
        description  => 'Varnish traffic logger - varnishstatsd',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -a "/usr/local/bin/varnishstatsd" -u root',
    }
}
