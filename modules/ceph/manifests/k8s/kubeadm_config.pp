class ceph::k8s::kubeadm_config(
    Array[Stdlib::Fqdn] $etcd_hosts,
    Stdlib::Fqdn        $apiserver,
    String              $kubernetes_version,
    String              $node_token,
    String              $pause_image,
    String              $pod_subnet,
) {
    # use puppet certs to contact etcd
    $k8s_etcd_cert_pub  = '/etc/kubernetes/pki/puppet_etcd_client.crt'
    $k8s_etcd_cert_priv = '/etc/kubernetes/pki/puppet_etcd_client.key'
    $k8s_etcd_cert_ca   = '/etc/kubernetes/pki/puppet_ca.pem'
    $puppet_cert_pub    = "/var/lib/puppet/ssl/certs/${::fqdn}.pem"
    $puppet_cert_priv   = "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem"
    $puppet_cert_ca     = '/var/lib/puppet/ssl/certs/ca.pem'

    file { '/etc/kubernetes':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
    file { '/etc/kubernetes/pki':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }
    file { $k8s_etcd_cert_pub:
        ensure    => present,
        source    => "file://${puppet_cert_pub}",
        show_diff => false,
        owner     => 'root',
        group     => 'root',
        mode      => '0444',
    }
    file { $k8s_etcd_cert_priv:
        ensure    => present,
        source    => "file://${puppet_cert_priv}",
        show_diff => false,
        owner     => 'root',
        group     => 'root',
        mode      => '0400',
    }
    file { $k8s_etcd_cert_ca:
        ensure => present,
        source => "file://${puppet_cert_ca}",
    }
    file { '/etc/kubernetes/kubeadm-init.yaml':
        ensure  => present,
        content => template('ceph/k8s/kubeadm/kubeadm-init.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }
    file{ '/etc/kubernetes/psp':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        require => File['/etc/kubernetes'],
    }
    file { '/etc/kubernetes/psp/base-pod-security-policies.yaml':
        ensure  => present,
        source  => 'puppet:///modules/ceph/k8s/kubeadm/base-pod-security-policies.yaml',
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes/psp'],
    }
}
