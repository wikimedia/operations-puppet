class profile::toolforge::k8s::haproxy (
    Array[Stdlib::Fqdn] $ingress_nodes = lookup('profile::toolforge::k8s::ingress_nodes',  {default_value => ['localhost']}),
    Stdlib::Port        $ingress_port  = lookup('profile::toolforge::k8s::ingress_port',   {default_value => 30000}),
    Array[Stdlib::Fqdn] $control_nodes = lookup('profile::toolforge::k8s::control_nodes',  {default_value => ['localhost']}),
    Stdlib::Port        $api_port      = lookup('profile::toolforge::k8s::apiserver_port', {default_value => 6443}),
    Stdlib::Port        $jobs_port     = lookup('profile::toolforge::jobs_api_port',       {default_value => 30001}),
) {
    class { 'haproxy::cloud::base': }

    file { '/etc/haproxy/conf.d/k8s-api-servers.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/toolforge/k8s/haproxy/k8s-api-servers.cfg.erb'),
        notify  => Service['haproxy'],
    }
    file { '/etc/haproxy/conf.d/k8s-ingress.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/toolforge/k8s/haproxy/k8s-ingress.cfg.erb'),
        notify  => Service['haproxy'],
    }

    if $::labsproject == 'toolsbeta' {
        file { '/etc/haproxy/conf.d/k8s-ingress-jobs.cfg':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('profile/toolforge/k8s/haproxy/k8s-ingress-jobs.cfg.erb'),
            notify  => Service['haproxy'],
        }
    }

    class { 'prometheus::haproxy_exporter': }
}
