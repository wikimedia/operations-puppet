# SPDX-License-Identifier: Apache-2.0
# SmokePing - monitor network latency
# https://oss.oetiker.ch/smokeping
# https://github.com/oetiker/SmokePing
#
# parameters: $active_server
# In a multi-server setup, set $active_server to the FQDN
# of the server that should send smokeping alerts.

class smokeping(
    Stdlib::Fqdn $active_server,
) {

    ensure_packages(['smokeping', 'dnsutils'])

    file { '/etc/smokeping/config.d':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['smokeping'],
    }

    if $active_server == $::fqdn {
        $alerts = true
    } else {
        $alerts = false
    }

    ['Targets', 'General', 'pathnames', 'Alerts', 'Probes'].each |String $f| {
        file { "/etc/smokeping/config.d/${f}":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template("smokeping/config.d/${f}.erb"),
            require => Package['smokeping'],
            notify  => Service['smokeping'],
        }
    }

    service { 'smokeping':
        ensure  => running,
        require => [
            Package['smokeping'],
            File['/etc/smokeping/config.d'],
        ],
    }

    profile::auto_restarts::service { 'smokeping': }
}
