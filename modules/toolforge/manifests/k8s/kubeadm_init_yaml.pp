class toolforge::k8s::kubeadm_init_yaml(
    Stdlib::Fqdn        $apiserver,
    String              $pod_subnet,
    Stdlib::Unixpath    $k8s_etcd_cert_pub,
    Stdlib::Unixpath    $k8s_etcd_cert_priv,
    Stdlib::Unixpath    $k8s_etcd_cert_ca,
    Array[Stdlib::Fqdn] $etcd_hosts,
    String              $kubernetes_version = '1.15.5',
    String              $node_token = undef,
    Optional[String]    $encryption_key = undef,
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

    file{ '/etc/kubernetes/psp':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        require => File['/etc/kubernetes'],
    }

    file { '/etc/kubernetes/psp/base-pod-security-policies.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/psp/base-pod-security-policies.yaml',
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes/psp'],
    }

    file { '/etc/kubernetes/toolforge-tool-role.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/toolforge-tool-role.yaml',
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/etc/kubernetes'],
    }

    file { '/etc/kubernetes/admission':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        require => File['/etc/kubernetes'],
    }

    file { '/etc/kubernetes/admission/admission.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/admission.yaml',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/etc/kubernetes/admission'],
    }

    file { '/etc/kubernetes/admission/eventconfig.yaml':
        ensure  => present,
        source  => 'puppet:///modules/toolforge/k8s/eventconfig.yaml',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/etc/kubernetes/admission'],
    }

    # This should never be set in the public repo for hiera. Keep it in a
    # private repo on a standalone puppetmaster since it is a simple shared key.
    if $encryption_key {
        file { '/etc/kubernetes/admission/encryption-conf.yaml':
            ensure    => present,
            content   => template('toolforge/k8s/encryption-conf.yaml.erb'),
            owner     => 'root',
            group     => 'root',
            mode      => '0400',
            require   => File['/etc/kubernetes/admission'],
            show_diff => false,
        }
    }
}
