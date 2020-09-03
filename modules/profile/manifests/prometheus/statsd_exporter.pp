class profile::prometheus::statsd_exporter (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
    Array[Hash]         $mappings         = lookup('profile::prometheus::statsd_exporter::mappings'),
    String              $relay_address    = lookup('statsd'),
){

    class { '::prometheus::statsd_exporter':
        mappings      => $mappings,
        relay_address => $relay_address,
    }

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    # Don't spam conntrack with localhost statsd clients
    ferm::client { 'statsd-exporter-client':
        proto   => 'udp',
        notrack => true,
        port    => '9125',
        drange  => '127.0.0.1',
    }

    ferm::service { 'prometheus-statsd-exporter':
        proto  => 'tcp',
        port   => '9112',
        srange => $ferm_srange,
    }
}
