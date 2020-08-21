class profile::prometheus::druid_exporter (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
    $druid_version    = lookup('profile::prometheus::druid_exporter::druid_version', { 'default_value' => '0.12.3' })
) {
    prometheus::druid_exporter { 'default':
        druid_version => $druid_version
    }
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ferm::service { 'prometheus-druid-exporter':
        proto  => 'tcp',
        port   => '8000',
        srange => $ferm_srange,
    }
}
