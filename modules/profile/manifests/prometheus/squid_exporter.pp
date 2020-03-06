# Installs prometheus-squid-exporter and open matching ACLs

class profile::prometheus::squid_exporter (
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    # Note that prometheus-squid-exporter is only in buster and up
    require_package('prometheus-squid-exporter')

    service { 'prometheus-squid-exporter':
        ensure  => running,
        require => Service['squid'], # Squid and not Squid3 again on buster
    }

    base::service_auto_restart { 'prometheus-squid-exporter': }

    ferm::service { 'prometheus-squid-exporter':
        proto  => 'tcp',
        port   => '9301',
        srange => $ferm_srange,
    }
}
