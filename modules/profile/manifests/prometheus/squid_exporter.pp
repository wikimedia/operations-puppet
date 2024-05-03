# SPDX-License-Identifier: Apache-2.0
# Installs prometheus-squid-exporter and open matching ACLs

class profile::prometheus::squid_exporter (
    Stdlib::HTTPUrl $http_proxy = lookup('http_proxy', {'default_value' => undef}),
) {
    ensure_packages('prometheus-squid-exporter')

    service { 'prometheus-squid-exporter':
        ensure  => running,
        require => Service['squid'],
    }

    if $http_proxy{
        $proxy_port = split($http_proxy, ':')[2]
        file { '/etc/default/prometheus-squid-exporter':
            mode    => '0444',
            content => template('profile/prometheus/squid-exporter.conf.erb'),
            notify  => Service['prometheus-squid-exporter'],
        }
    }

    profile::auto_restarts::service { 'prometheus-squid-exporter': }
}
