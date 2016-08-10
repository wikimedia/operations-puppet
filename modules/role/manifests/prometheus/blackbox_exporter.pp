# == Class: role::prometheus::blackbox_exporter
#
# Role to provision prometheus blackbox / active checks exporter. See
# https://github.com/prometheus/blackbox_exporter and the module's documentation.

class role::prometheus::blackbox_exporter {
    include ::prometheus::blackbox_exporter

    ferm::service { 'prometheus-blackbox-exporter':
        proto  => 'tcp',
        port   => '9115',
        srange => '$DOMAIN_NETWORKS',
    }
}
