# == Class: tlsproxy::prometheus

class tlsproxy::prometheus {
    $prometheus_nodes = lookup('prometheus_nodes', {'default_value' => []})

    nginx::site { 'tlsproxy-prometheus':
        content => template('tlsproxy/prometheus-nginx.conf.erb'),
    }
}
