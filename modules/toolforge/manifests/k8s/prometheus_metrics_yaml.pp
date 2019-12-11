class toolforge::k8s::prometheus_metrics_yaml(
) {
    require ::toolforge::k8s::kubeadm # because /etc/kubernetes

    file { '/etc/kubernetes/prometheus_metrics.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/prometheus_metrics.yaml',
        require => File['/etc/kubernetes'],
    }

    file { '/etc/kubernetes/metrics-server.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/metrics-server.yaml',
        require => File['/etc/kubernetes'],
    }
}
