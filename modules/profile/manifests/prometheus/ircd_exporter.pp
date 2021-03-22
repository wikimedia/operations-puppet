class profile::prometheus::ircd_exporter (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
) {
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    package { 'prometheus-ircd-exporter':
        ensure => absent,
    }

    service { 'prometheus-ircd-exporter':
        ensure => stopped,
    }

    ferm::service { 'prometheus-ircd-exporter':
        ensure => absent,
        proto  => 'tcp',
        port   => '9197',
        srange => $ferm_srange,
    }

    base::service_auto_restart { 'prometheus-ircd-exporter':
        ensure => absent,
    }
}
