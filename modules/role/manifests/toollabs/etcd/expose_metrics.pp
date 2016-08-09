# Helper class that sets up an nginx proxy to expose /metrics endpoint
# of etcd to the wider world, so things like prometheus can hit it.
class role::toollabs::etcd::expose_metrics {
    $exposed_port = '9051'

    nginx::site { 'expose_etcd_metrics':
        content => template('role/toollabs/etcd_expose_metrics.nginx.erb'),
    }

    ferm::service { 'etcd-metrics':
        proto => 'tcp',
        port  => $exposed_port,
    }
}
