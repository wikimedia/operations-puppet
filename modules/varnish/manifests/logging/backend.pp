# == Class varnish::logging::backend
#
# This class sets up analytics/logging needed by servers running varnish backend
#
# === Parameters
#
# [*statsd_host*]
#   The statsd host to send stats to.
#
# [*varnishmtail_backend_progs*]
#   Directory with varnish backend mtail programs.
#   Defaults to /etc/varnishmtail-backend/.
#
# [*varnishmtail_backend_port*]
#   Port on which to bind the varnish backend mtail instance.
#   Defaults to 3904.
#
class varnish::logging::backend(
    $statsd_host,
    $varnishmtail_backend_progs='/etc/varnishmtail-backend/',
    $varnishmtail_backend_port=3904,
){
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

    # Parse Backend-Timing origin server response header and make the values
    # available to Prometheus
    ::varnish::logging::backendtiming { 'backendtiming':
    }

    mtail::program { 'varnishbackend':
        source      => 'puppet:///modules/mtail/programs/varnishbackend.mtail',
        destination => '/etc/varnishmtail-backend',
        notify      => Service['varnishmtail-backend'],
    }

    ::varnish::logging::statsd { 'default':
        ensure        => absent,
        statsd_server => $statsd_host,
        key_prefix    => "varnish.${::site}.backends",
    }
}
