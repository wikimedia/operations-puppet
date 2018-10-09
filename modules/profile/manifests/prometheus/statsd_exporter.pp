class profile::prometheus::statsd_exporter (
    Array[String] $prometheus_nodes = hiera('prometheus_nodes'),
    Array[Hash] $mappings = hiera('profile::prometheus::statsd_exporter::mappings'),
    String $relay_address = hiera('statsd'),
) {
    class { '::prometheus::statsd_exporter':
        mappings      => $mappings,
        relay_address => $relay_address,
    }

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ferm::service { 'prometheus-statsd-exporter':
        proto  => 'tcp',
        port   => '9112',
        srange => $ferm_srange,
    }
}
