class kubeadm::init_yaml (
    Stdlib::Fqdn                  $apiserver,
    String                        $pod_subnet,
    Boolean                       $stacked = false,
    Optional[Stdlib::Unixpath]    $k8s_etcd_cert_pub,
    Optional[Stdlib::Unixpath]    $k8s_etcd_cert_priv,
    Optional[Stdlib::Unixpath]    $k8s_etcd_cert_ca,
    Optional[Array[Stdlib::Fqdn]] $etcd_hosts,
    String                        $kubernetes_version = '1.15.5',
    String                        $node_token = undef,
    Optional[String]              $encryption_key = undef,
) {
    # because /etc/kubernetes
    require ::kubeadm::core

    file { '/etc/kubernetes/kubeadm-init.yaml':
        ensure  => present,
        content => template('kubeadm/init.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }

    file { '/etc/kubernetes/psp':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        require => File['/etc/kubernetes'],
    }

    file { '/etc/kubernetes/psp/base-pod-security-policies.yaml':
        ensure  => present,
        source  => 'puppet:///modules/kubeadm/psp/base-pod-security-policies.yaml',
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes/psp'],
    }
}
