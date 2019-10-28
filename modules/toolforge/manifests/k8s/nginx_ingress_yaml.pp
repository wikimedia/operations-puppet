class toolforge::k8s::nginx_ingress_yaml(
) {
    require ::toolforge::k8s::kubeadm

    file { '/etc/kubernetes/psp/nginx-ingress-psp.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/psp/nginx-ingress-psp.yaml',
        require => File['/etc/kubernetes'],
    }

    file { '/etc/kubernetes/nginx-ingress.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/nginx-ingress.yaml',
        require => File['/etc/kubernetes'],
    }
}
