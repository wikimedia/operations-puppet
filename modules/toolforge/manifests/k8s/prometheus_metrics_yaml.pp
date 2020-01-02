class toolforge::k8s::prometheus_metrics_yaml(
) {
    require ::toolforge::k8s::kubeadm # because /etc/kubernetes

    # for this to work you need to generate a x509 cert using the admin script
    # the generated certs should be then moved as secrets to the private repo
    # in a control node:
    #   root:~# wmcs-k8s-get-cert prometheus
    #
    # See also: profile::toolforge::prometheus
    # See also: https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Deploying_k8s
    file { '/etc/kubernetes/prometheus_metrics.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/prometheus_metrics.yaml',
        require => File['/etc/kubernetes'],
    }

    # for this to work you need to generate a x509 cert and create a k8s secret
    # in a control node:
    #   root:~# wmcs-k8s-secret-for-cert -n kube-system -s metrics-server-certs -a metrics-server
    #
    # See also: https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Deploying_k8s
    file { '/etc/kubernetes/metrics-server.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/metrics-server.yaml',
        require => File['/etc/kubernetes'],
    }

    file { '/etc/kubernetes/kube-state-metrics.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/kube-state-metrics.yaml',
        require => File['/etc/kubernetes'],
    }
}
