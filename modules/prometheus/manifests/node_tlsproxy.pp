# == Class: prometheus::node_tlsproxy

class prometheus::node_tlsproxy {
    file { "/etc/nginx/lua/prometheus.lua":
        source  => 'puppet:///modules/tlsproxy/nginx-lua-prometheus.lua',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/etc/nginx/lua'],
    }

    nginx::site { 'node-tlsproxy-prometheus':
        content => template('prometheus/prometheus-node-tlsproxy-nginx.erb'),
    }
}
