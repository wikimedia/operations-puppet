# == Class: tlsproxy::prometheus

class tlsproxy::prometheus {
    file { '/etc/nginx/lua/prometheus.lua':
        source  => 'puppet:///modules/tlsproxy/nginx-lua-prometheus.lua',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/etc/nginx/lua'],
    }

    $prometheus_nodes = hiera('prometheus_nodes', [])

    nginx::site { 'tlsproxy-prometheus':
        content => template('tlsproxy/prometheus-nginx.conf.erb'),
    }
}
