# == Class varnish::logging
#
# This class sets up analytics/logging needed by cache servers
#
# === Parameters
#
# [*cache_cluster*]
#   The cache cluster we're part of.
#
# [*statsd_host*]
#   The statsd host to send stats to.
#
# [*forward_syslog*]
#   Host and port to forward syslog events to. Disable forwarding by passing an
#   empty string (default).
#
# [*mtail_progs*]
#   Directory with mtail programs. Defaults to /etc/mtail.
#
# [*varnishmtail_backend_progs*]
#   Directory with varnish backend mtail programs.
#   Defaults to /etc/varnishmtail-backend/.
#
# [*varnishmtail_backend_port*]
#   Port on which to bind the varnish backend mtail instance.
#   Defaults to 3904.
#
class varnish::logging(
    $cache_cluster,
    $statsd_host,
    $forward_syslog='',
    $mtail_progs='/etc/mtail',
    $varnishmtail_backend_progs='/etc/varnishmtail-backend/',
    $varnishmtail_backend_port=3904,
){
    rsyslog::conf { 'varnish':
        content  => template('varnish/rsyslog.conf.erb'),
        priority => 80,
    }

    file { '/usr/local/bin/varnishmtail':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/varnish/varnishmtail',
        notify => Systemd::Service['varnishmtail'],
    }

    systemd::service { 'varnishmtail':
        ensure  => present,
        content => systemd_template('varnishmtail'),
        restart => true,
        require => File['/usr/local/bin/varnishmtail'],
    }

    file { '/usr/local/bin/varnishmtail-backend':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/varnish/varnishmtail-backend',
        notify => Systemd::Service['varnishmtail-backend'],
    }

    systemd::service { 'varnishmtail-backend':
        ensure  => present,
        content => systemd_template('varnishmtail-backend'),
        restart => true,
        require => File['/usr/local/bin/varnishmtail-backend'],
    }

    # Client connection stats from the 'X-Connection-Properties'
    # header set by the SSL terminators.
    ::varnish::logging::xcps { 'xcps':
        statsd_server => $statsd_host,
    }

    ::varnish::logging::statsd { 'default':
        statsd_server => $statsd_host,
        key_prefix    => "varnish.${::site}.backends",
    }

    # Parse varnishlogs for request statistics and send to statsd.
    varnish::logging::reqstats { 'frontend':
        key_prefix => "varnish.${::site}.${cache_cluster}.frontend.request",
        statsd     => $statsd_host,
    }

    ::varnish::logging::xcache { 'xcache':
        key_prefix    => "varnish.${::site}.${cache_cluster}.xcache",
        statsd_server => $statsd_host,
    }

    file { '/usr/local/bin/varnishslowlog':
        source => 'puppet:///modules/varnish/varnishslowlog.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
