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
#    statsd_server => 'statsd.eqiad.wmnet:8125
#  }
#
define varnish::logging::xcps( $statsd_server = 'statsd' ) {
    include varnish::common

    if (hiera('varnish_version4', false)) {
        # Use v4 version of varnishxcps
        $varnish4_python_suffix = '4'
    } else {
        $varnish4_python_suffix = ''
    }

    file { '/usr/local/bin/varnishxcps':
        source  => "puppet:///modules/varnish/varnishxcps${varnish4_python_suffix}",
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => File['/usr/local/lib/python2.7/dist-packages/varnishlog.py'],
        notify  => Service['varnishxcps'],
    }

    base::service_unit { 'varnishxcps':
        ensure         => present,
        systemd        => true,
        strict         => false,
        template_name  => 'varnishxcps',
        require        => File['/usr/local/bin/varnishxcps'],
        service_params => {
            enable => true,
        },
    }

    nrpe::monitor_service { 'varnishxcps':
        ensure       => present,
        description  => 'Varnish traffic logger - varnishxcps',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -a "/usr/local/bin/varnishxcps" -u root',
    }
}
