class toolforge::k8s::kubeadm_init(
    Stdlib::Fqdn        $apiserver,
    String              $pod_subnet,
    Array[Stdlib::Fqdn] $etcd_hosts = [],
    String              $kubernetes_version = '1.15.0',
    String              $node_token = undef,
) {
    file { '/etc/kubernetes/kubeadm-init.yaml':
        ensure  => present,
        content => template('toolforge/k8s/kubeadm-init.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }
}
