# == Define: varnish::logging::rls
#
#  Accumulate browser cache hit ratio and total request volume statistics for
#  ResourceLoader requests (/w/load.php) and expose metrics to prometheus.
#
define varnish::logging::rls {
    include ::varnish::common

    file { '/usr/local/bin/varnishrls':
        ensure => absent,
        notify => Service['varnishrls'],
    }

    systemd::service { 'varnishrls':
        ensure  => absent,
        content => '',
    }

    nrpe::monitor_service { 'varnishrls':
        ensure       => absent,
        description  => 'Varnish traffic logger - varnishrls',
        nrpe_command => '/bin/true',
    }

    mtail::program { 'varnishrls':
        source => 'puppet:///modules/mtail/programs/varnishrls.mtail',
        notify => Service['varnishmtail'],
    }
}
