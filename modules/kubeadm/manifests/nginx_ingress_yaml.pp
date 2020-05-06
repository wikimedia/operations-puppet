class kubeadm::nginx_ingress_yaml (
) {
    require ::kubeadm::core # because /etc/kubernetes

    file { '/etc/kubernetes/psp/nginx-ingress-psp.yaml':
        ensure  => present,
        source  => 'puppet:///modules/kubeadm/psp/nginx-ingress-psp.yaml',
        require => File['/etc/kubernetes'],
    }

    file { '/etc/kubernetes/nginx-ingress.yaml':
        ensure  => present,
        source  => 'puppet:///modules/kubeadm/nginx-ingress.yaml',
        require => File['/etc/kubernetes'],
    }
}
