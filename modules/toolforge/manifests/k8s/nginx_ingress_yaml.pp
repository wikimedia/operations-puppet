class toolforge::k8s::nginx_ingress_yaml (
) {
    # make sure you declare ::kubeadm::core somewhere in the calling profile
    # because /etc/kubernetes

    file { '/etc/kubernetes/psp/nginx-ingress-psp.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/nginx-ingress-psp.yaml',
        require => File['/etc/kubernetes'],
    }

    file { '/etc/kubernetes/nginx-ingress.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/nginx-ingress.yaml',
        require => File['/etc/kubernetes'],
    }
}
