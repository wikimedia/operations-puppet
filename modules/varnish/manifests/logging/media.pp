# == Define: varnish::logging::media
#
#  Accumulate browser cache hit ratio and total request volume statistics
#  for Media requests and report to StatsD.
#
# === Parameters
#
# [*statsd_server*]
#   StatsD server address, in "host:port" format.
#   Defaults to localhost:8125.
#
# === Examples
#
#  varnish::logging::media {
#    statsd_server => 'statsd.eqiad.wmnet:8125
#  }
#
define varnish::logging::media( $statsd_server = 'statsd' ) {
    include ::varnish::common

    file { '/usr/local/bin/varnishmedia':
        source  => 'puppet:///modules/varnish/varnishmedia',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => File['/usr/local/lib/python2.7/dist-packages/cachestats.py'],
        notify  => Service['varnishmedia'],
    }

    base::service_unit { 'varnishmedia':
        ensure         => present,
        systemd        => true,
        strict         => false,
        template_name  => 'varnishmedia',
        require        => File['/usr/local/bin/varnishmedia'],
        subscribe      => File['/usr/local/lib/python2.7/dist-packages/cachestats.py'],
        service_params => {
            enable => true,
        },
    }

    nrpe::monitor_service { 'varnishmedia':
        ensure       => present,
        description  => 'Varnish traffic logger - varnishmedia',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -a "/usr/local/bin/varnishmedia" -u root',
    }
}
