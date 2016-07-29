# == Class: role::prometheus::node_exporter
#
# Role to provision prometheus machine metrics exporter. See also
# https://github.com/prometheus/node_exporter and the module's documentation.

class role::prometheus::node_exporter {
    if os_version('debien >= jessie') {
        # Doesn't work for trusty or jessie yet
        include ::prometheus::node_exporter
    }

    ferm::service { 'prometheus-node-exporter':
        proto  => 'tcp',
        port   => '9100',
        srange => '$DOMAIN_NETWORKS',
    }
}
