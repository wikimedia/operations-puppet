class profile::prometheus::rsyslog_exporter (
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    class { '::prometheus::rsyslog_exporter':
        listen_address => ':9105',
    }

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ferm::service { 'prometheus-rsyslog_exporter':
        proto  => 'tcp',
        port   => '9105',
        srange => $ferm_srange,
    }
}
