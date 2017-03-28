# == Class: tlsproxy::prometheus

class tlsproxy::prometheus {
    $prometheus_nodes = hiera('prometheus_nodes', [])

    nginx::site { 'tlsproxy-prometheus':
        content => template('tlsproxy/prometheus-nginx.conf.erb'),
    }
}
