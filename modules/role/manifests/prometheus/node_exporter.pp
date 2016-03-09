# == Class: role::prometheus::node_exporter
#
# Role to provision prometheus machine metrics exporter. See also
# https://github.com/prometheus/node_exporter and the module's documentation.

class role::prometheus::node_exporter {
    # Until we have trusty & precise packages
    if os_version('debian >= jessie') {
        include ::prometheus::node_exporter

        ferm::service { 'prometheus-node-exporter':
            proto  => 'tcp',
            port   => '9100',
            srange => '$INTERNAL',
        }
    }
}
