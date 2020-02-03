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
# [*mtail_progs*]
#   Directory with mtail programs. Defaults to /etc/mtail.
#
class varnish::logging(
    $cache_cluster,
    $statsd_host,
    $mtail_progs='/etc/mtail',
){
    require_package('python3-logstash')

    rsyslog::conf { 'varnish':
        ensure   => absent,
        priority => 80,
    }

    rsyslog::conf { 'varnish_pipeline':
        content  => template('varnish/rsyslog.conf.erb'),
        priority => 20,
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

    mtail::program { 'varnishreqstats':
        source => 'puppet:///modules/mtail/programs/varnishreqstats.mtail',
        notify => Service['varnishmtail'],
    }

    mtail::program { 'varnishttfb':
        source => 'puppet:///modules/mtail/programs/varnishttfb.mtail',
        notify => Service['varnishmtail'],
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
