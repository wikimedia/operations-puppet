# == Define varnish::logging::xcache:
# Logs X-Cache hit-related stats to statsd
#
# === Parameters
#
# [*statsd_server*]
#   StatsD server address, in "host:port" format.
#   Defaults to localhost:8125.
#
# [*key_prefix*]
#   Prefix of the stats that will be sent to statsd.
#   Within this prefix, it will create counters named:
#   hit-front, hit-local, hit-remote, int-front, int-local, int-remote, misspass
#   Default 'test.varnish.xcache'
#
# === Examples
#
#  varnish::logging::xcache {
#    statsd_server => 'statsd.eqiad.wmnet:8125',
#    key_prefix => "varnish.${::site}.${::cluster}.xcache"
#  }
#
define varnish::logging::xcache(
    $statsd_server = 'localhost:8125',
    $key_prefix = 'test.varnish.xcache',
) {
    include ::varnish::common

    file { '/usr/local/bin/varnishxcache':
        source  => 'puppet:///modules/varnish/varnishxcache',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => File['/usr/local/lib/python2.7/dist-packages/varnishlog.py'],
        notify  => Service['varnishxcache'],
    }

    base::service_unit { 'varnishxcache':
        ensure         => present,
        systemd        => true,
        strict         => false,
        template_name  => 'varnishxcache',
        require        => File['/usr/local/bin/varnishxcache'],
        subscribe      => File['/usr/local/lib/python2.7/dist-packages/varnishlog.py'],
        service_params => {
            require => Service['varnish-frontend'],
            enable  => true,
        },
    }

    nrpe::monitor_service { 'varnishxcache':
        ensure       => present,
        description  => 'Varnish traffic logger - varnishxcache',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -a "/usr/local/bin/varnishxcache" -u root',
    }
}
