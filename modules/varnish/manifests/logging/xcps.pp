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
        ensure => stopped,
    }

    nrpe::monitor_service { 'varnishxcps':
        ensure => absent,
    }

    mtail::program { 'varnishxcps':
        source => 'puppet:///modules/mtail/programs/varnishxcps.mtail',
        notify => Service['varnishmtail'],
    }
}
