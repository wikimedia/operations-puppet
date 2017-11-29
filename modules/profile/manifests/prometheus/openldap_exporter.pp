class profile::prometheus::openldap_exporter (
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    include ::prometheus::openldap_exporter
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ferm::service { 'prometheus-openldap-exporter':
        proto  => 'tcp',
        port   => '9142',
        srange => $ferm_srange,
    }
}
