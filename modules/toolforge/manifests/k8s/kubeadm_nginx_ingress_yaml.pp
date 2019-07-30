class toolforge::k8s::kubeadm_nginx_ingress_yaml(
) {
    require ::toolforge::k8s::kubeadm

    file { '/etc/kubernetes/kubeadm-nginx-ingress-psp.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/kubeadm-nginx-ingress-psp.yaml',
        require => File['/etc/kubernetes'],
    }

    file { '/etc/kubernetes/kubeadm-nginx-ingress.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/kubeadm-nginx-ingress.yaml',
        require => File['/etc/kubernetes'],
    }
}
