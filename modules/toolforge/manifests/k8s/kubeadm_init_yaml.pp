class toolforge::k8s::kubeadm_init_yaml(
    Stdlib::Fqdn        $apiserver,
    String              $pod_subnet,
    Stdlib::Unixpath    $k8s_etcd_cert_pub,
    Stdlib::Unixpath    $k8s_etcd_cert_priv,
    Stdlib::Unixpath    $k8s_etcd_cert_ca,
    Array[Stdlib::Fqdn] $etcd_hosts,
    String              $kubernetes_version = '1.15.0',
    String              $node_token = undef,
) {
    require ::toolforge::k8s::kubeadm

    file { '/etc/kubernetes/kubeadm-init.yaml':
        ensure  => present,
        content => template('toolforge/k8s/kubeadm-init.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }
}
