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

    # TODO: move these into /etc/kubernetes/psp or perhaps all in one file
    file { '/etc/kubernetes/kubeadm-system-psp.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/kubeadm-system-psp.yaml',
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }

    file { '/etc/kubernetes/kubeadm-default-psp.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/kubeadm-default-psp.yaml',
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }
}
