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
class varnish::logging(
    $cache_cluster,
    $statsd_host,
    $forward_syslog='',
    $mtail_progs='/etc/mtail',
){
    require_package('python3-logstash')

    rsyslog::conf { 'varnish':
        content  => template('varnish/rsyslog.conf.erb'),
        priority => 80,
    }

    exec { 'mask_default_mtail':
        command => '/bin/systemctl mask mtail.service',
        creates => '/etc/systemd/system/mtail.service',
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

    # Client connection stats from the 'X-Connection-Properties'
    # header set by the SSL terminators.
    ::varnish::logging::xcps { 'xcps':
    }

    # Parse varnishlogs for request statistics and send to statsd.
    varnish::logging::reqstats { 'frontend':
        key_prefix => "varnish.${::site}.${cache_cluster}.frontend.request",
        statsd     => $statsd_host,
    }

    ::varnish::logging::xcache { 'xcache':
    }

    if $cache_cluster == 'upload' {
        # Media browser cache hit rate and request volume stats.
        ::varnish::logging::media { 'media':
        }
    }

    file { "/usr/local/lib/python${::varnish::common::python_version}/dist-packages/wikimedia_varnishlogconsumer.py":
        source => 'puppet:///modules/varnish/wikimedia_varnishlogconsumer.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/usr/local/bin/varnishslowlog':
        source => 'puppet:///modules/varnish/varnishslowlog.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/bin/varnishospital':
        source => 'puppet:///modules/varnish/varnishospital.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/bin/varnishfetcherr':
        source => 'puppet:///modules/varnish/varnishfetcherr.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/bin/varnishtlsinspector':
        source => 'puppet:///modules/varnish/varnishtlsinspector.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    systemd::service { 'varnish-frontend-tlsinspector':
        ensure         => absent,
        content        => systemd_template('varnishtlsinspector'),
        restart        => true,
        service_params => {
            require => Service['varnish-frontend'],
            enable  => false,
        },
        subscribe      => [
            File['/usr/local/bin/varnishtlsinspector'],
            File["/usr/local/lib/python${::varnish::common::python_version}/dist-packages/wikimedia_varnishlogconsumer.py"],
        ]
    }
}
