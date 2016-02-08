# == Define: varnish::logging::age
#
#  Report response age to StatsD (where "response age" is the difference
#  between the current time and the time at which the response was generated
#  by an Apache backend.
#
# === Parameters
#
# [*statsd_server*]
#   StatsD server address, in "host:port" format.
#   Defaults to localhost:8125.
#
# === Examples
#
#  varnish::logging::age {
#    statsd_server => 'statsd.eqiad.wmnet:8125
#  }
#
define varnish::logging::age( $statsd_server = 'statsd' ) {
    include varnish::common

    file { '/usr/local/bin/varnishage':
        source  => 'puppet:///modules/varnish/varnishage',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => File['/usr/local/lib/python2.7/dist-packages/varnishlog.py'],
        notify  => Service['varnishage'],
    }

    base::service_unit { 'varnishage':
        ensure         => present,
        systemd        => true,
        strict         => false,
        template_name  => 'varnishage',
        require        => File['/usr/local/bin/varnishage'],
        service_params => {
            enable => true,
        },
    }
}
