class toolforge::k8s::nginx_ingress_yaml (
    Integer $ingress_replicas = 2
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
        content => template('toolforge/k8s/nginx-ingress.yaml.erb'),
        require => File['/etc/kubernetes'],
    }
}
