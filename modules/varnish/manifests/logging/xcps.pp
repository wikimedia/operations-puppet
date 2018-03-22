# == Define: varnish::logging::xcps
#
# Mtail program parsing X-Connection-Properties header from the SSL terminators
# and making metrics available to Prometheus.
#
# === Parameters
#
# === Examples
#
#  varnish::logging::xcps {
#  }
#
define varnish::logging::xcps {
    include ::varnish::common

    file { '/usr/local/bin/varnishxcps':
        ensure => absent,
        notify => Service['varnishxcps'],
    }

    systemd::service { 'varnishxcps':
        ensure  => absent,
        content => '',
    }

    nrpe::monitor_service { 'varnishxcps':
        ensure       => absent,
        description  => 'Varnish traffic logger - varnishxcps',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -a "/usr/local/bin/varnishxcps" -u root',
    }

    mtail::program { 'varnishxcps':
        source => 'puppet:///modules/mtail/programs/varnishxcps.mtail',
        notify => Service['varnishmtail'],
    }
}
