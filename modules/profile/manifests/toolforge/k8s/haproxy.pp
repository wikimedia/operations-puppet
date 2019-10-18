class profile::toolforge::k8s::haproxy (
    Array[Stdlib::Fqdn] $k8s_nodes    = lookup('profile::toolforge::k8s::worker_nodes'),
    Stdlib::Port        $ingress_port = lookup('profile::toolforge::k8s::ingress_port', {default_value => 30000}),
        $servers = hiera('profile::toolforge::k8s::api_servers'),
    ) {
    class { 'haproxy':
        template => 'profile/toolforge/k8s/haproxy/haproxy.cfg.erb',
        monitor  => false,
    }

    file { '/etc/haproxy/conf.d/k8s-api-servers.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/toolforge/k8s/haproxy/k8s-api-servers.cfg.erb'),
    }

    file { '/etc/haproxy/conf.d/k8s-ingress.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/toolforge/k8s/haproxy/k8s-ingress.cfg.erb'),
    }

    exec { 'toolforge_k8s_reload_haproxy_service':
        command     => '/bin/systemctl reload haproxy',
        subscribe   => File['/etc/haproxy/conf.d/k8s-api-servers.cfg'],
        refreshonly => true,
    }
}
