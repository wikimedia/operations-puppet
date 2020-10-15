class profile::prometheus::nic_saturation_exporter (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
    Wmflib::Ensure      $ensure           = lookup('profile::prometheus::nic_saturation_exporter::ensure')
) {
    class {'prometheus::nic_saturation_exporter':
        ensure         => $ensure,
        listen_address => $facts['networking']['ip']
    }

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ferm::service { 'prometheus-nic-saturation-exporter':
        ensure => $ensure,
        proto  => 'tcp',
        port   => '9710',
        srange => $ferm_srange,
    }
}
