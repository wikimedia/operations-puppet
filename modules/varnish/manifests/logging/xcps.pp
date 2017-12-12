# == Define: varnish::logging::xcps
#
# Accumulates client connection statistics from the SSL terminators
# by parsing X-Connection-Properties headers. Reports to StatsD.
#
# === Parameters
#
# [*statsd_server*]
#   StatsD server address, in "host:port" format.
#   Defaults to localhost:8125.
#
# === Examples
#
#  varnish::logging::xcps {
#    statsd_server => 'statsd.eqiad.wmnet:8125'
#  }
#
define varnish::logging::xcps( $statsd_server = 'statsd' ) {
    include ::varnish::common

    file { '/usr/local/bin/varnishxcps':
        source  => 'puppet:///modules/varnish/varnishxcps',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => File['/usr/local/lib/python2.7/dist-packages/cachestats.py'],
        notify  => Service['varnishxcps'],
    }

    systemd::service { 'varnishxcps':
        ensure         => present,
        content        => systemd_template('varnishxcps'),
        restart        => true,
        require        => File['/usr/local/bin/varnishxcps'],
        subscribe      => File['/usr/local/lib/python2.7/dist-packages/cachestats.py'],
        service_params => {
            require => Service['varnish-frontend'],
            enable  => true,
        },
    }

    nrpe::monitor_service { 'varnishxcps':
        ensure       => present,
        description  => 'Varnish traffic logger - varnishxcps',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -a "/usr/local/bin/varnishxcps" -u root',
    }

    mtail::program { 'varnishxcps':
        source => 'puppet:///modules/mtail/programs/varnishxcps.mtail',
    }
}
