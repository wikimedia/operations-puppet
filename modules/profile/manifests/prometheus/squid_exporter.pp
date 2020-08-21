# Installs prometheus-squid-exporter and open matching ACLs

class profile::prometheus::squid_exporter (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
    Stdlib::HTTPUrl $http_proxy = lookup('http_proxy', {'default_value' => undef}),
) {
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    # Note that prometheus-squid-exporter is only in buster and up
    require_package('prometheus-squid-exporter')

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


    base::service_auto_restart { 'prometheus-squid-exporter': }

    ferm::service { 'prometheus-squid-exporter':
        proto  => 'tcp',
        port   => '9301',
        srange => $ferm_srange,
    }
}
