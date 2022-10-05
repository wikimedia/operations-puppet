# SPDX-License-Identifier: Apache-2.0
# Installs prometheus-squid-exporter and open matching ACLs

class profile::prometheus::squid_exporter (
    Stdlib::HTTPUrl $http_proxy = lookup('http_proxy', {'default_value' => undef}),
) {
    # Note that prometheus-squid-exporter is only in buster and up
    ensure_packages('prometheus-squid-exporter')

    service { 'prometheus-squid-exporter':
        ensure  => running,
        require => Service['squid'], # Squid and not Squid3 again on buster
    }

    if $http_proxy{
        $proxy_port = split($http_proxy, ':')[2]
        file { '/etc/default/prometheus-squid-exporter':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('profile/prometheus/squid-exporter.conf.erb'),
            notify  => Service['prometheus-squid-exporter'],
        }
    }


    profile::auto_restarts::service { 'prometheus-squid-exporter': }
}
