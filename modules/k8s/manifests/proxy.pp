class k8s::proxy(
    $master_host,
    $use_package = false,
    $proxy_mode = 'iptables',
    $masquerade_all = true,
) {
    include ::k8s::infrastructure_config

    $master_ip = ipresolve($master_host, 4, $::nameservers[0])

    if $use_package {
        require_package('kubernetes-node')
    } else {
        file { '/usr/bin/kube-proxy':
            ensure => link,
            target => '/usr/local/bin/kube-proxy',
        }
    }

    file { '/etc/default/kube-proxy':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('k8s/kube-proxy.default.erb'),
    }

    base::service_unit { 'kube-proxy':
        systemd   => true,
        upstart   => true,
        subscribe => File['/etc/kubernetes/kubeconfig'],
    }
}
