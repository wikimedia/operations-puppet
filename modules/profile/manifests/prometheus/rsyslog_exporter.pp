class profile::prometheus::rsyslog_exporter (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
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
