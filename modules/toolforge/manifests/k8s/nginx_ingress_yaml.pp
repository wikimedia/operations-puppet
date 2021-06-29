class toolforge::k8s::nginx_ingress_yaml (
    Integer $ingress_replicas = 2,
) {
    # Helm 3 from component/kubeadm-*
    require_package('helm')

    # make sure you declare ::kubeadm::core somewhere in the calling profile
    # because /etc/kubernetes

    file { '/etc/kubernetes/psp/nginx-ingress-psp.yaml':
        ensure  => absent,
    }

    file { '/etc/kubernetes/nginx-ingress-helm-values.yaml':
        ensure  => present,
        content => template('toolforge/k8s/nginx-ingress-helm-values.yaml.erb'),
        require => File['/etc/kubernetes'],
    }

    file { '/etc/kubernetes/nginx-ingress.yaml':
        ensure  => absent,
    }
}
