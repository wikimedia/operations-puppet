class profile::prometheus::pdns_exporter (
    Array[Stdlib::Fqdn] $prometheus_nodes = lookup('prometheus_nodes'),
) {
    require_package('prometheus-pdns-exporter')

    service { 'prometheus-pdns-exporter':
        ensure  => running,
    }

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ferm::service { 'prometheus-pdns-exporter':
        proto  => 'tcp',
        port   => '9192',
        srange => $ferm_srange,
    }

    base::service_auto_restart { 'prometheus-pdns-exporter': }
}
