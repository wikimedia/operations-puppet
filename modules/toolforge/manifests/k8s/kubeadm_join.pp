class toolforge::k8s::kubeadm_join(
    Stdlib::Fqdn $apiserver,
    String       $node_token = undef,
) {
    file { '/etc/kubernetes/kubeadm-join.yaml':
        ensure  => present,
        content => template('toolforge/k8s/kubeadm-join.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }
}
