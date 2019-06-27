class k8s::proxy(
    String $master_host,
    String $proxy_mode = 'iptables',
    Boolean $masquerade_all = true,
    String $kubeconfig = '/etc/kubernetes/kubeconfig',
) {
    require ::k8s::infrastructure_config

    require_package('kubernetes-node')

    file { '/etc/default/kube-proxy':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('k8s/kube-proxy.default.erb'),
        notify  => Service['kube-proxy'],
    }

    service { 'kube-proxy':
        ensure    => running,
        enable    => true,
        subscribe => [
            File[$kubeconfig],
            File['/etc/default/kube-proxy'],
        ],

    }
}
