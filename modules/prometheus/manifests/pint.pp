# SPDX-License-Identifier: Apache-2.0

# pint (https://github.com/cloudflare/pint) is used to check Prometheus
# alerting and recording rules for problems. This class takes care of
# deploying the base pint scaffolding and start watching alerts.
#
# Additional 'live' checks can be performed (e.g. if metrics still exist)
# by adding prometheus::pint::source to an existing prometheus instance.

class prometheus::pint (
    Wmflib::Ensure $ensure = present,
    Stdlib::Port $listen_port = 9123,
    Array[Stdlib::Unixpath] $watch_paths = ['/srv/alerts', '/srv/alerts-thanos'],
) {
    ensure_packages('pint')

    require prometheus::assemble_config

    file { '/etc/prometheus/pint.hcl.d':
        ensure  => directory,
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        recurse => true,
        purge   => true,
    }

    exec { 'assemble pint.hcl':
        onlyif  => 'prometheus-assemble-config --onlyif pint',
        command => 'prometheus-assemble-config pint',
        notify  => Service['pint'],
        path    => '/usr/local/bin',
    }

    systemd::service { 'pint':
        ensure   => $ensure,
        content  => init_template('pint', 'systemd_override'),
        override => true,
        restart  => true,
    }

    profile::auto_restarts::service { 'pint':
        ensure => $ensure,
    }
}
