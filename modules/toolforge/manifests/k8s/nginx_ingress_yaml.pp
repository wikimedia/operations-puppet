class toolforge::k8s::nginx_ingress_yaml (
    Integer $ingress_replicas = 2,
) {
    # ::kubeadm::helm is practically a dependency, but it's required in
    # the relevant profile to avoid style guide violations

    # make sure you declare ::kubeadm::core somewhere in the calling profile
    # because /etc/kubernetes

    file { '/etc/kubernetes/nginx-ingress-helm-values.yaml':
        ensure  => present,
        content => template('toolforge/k8s/nginx-ingress-helm-values.yaml.erb'),
        require => File['/etc/kubernetes'],
    }
}
