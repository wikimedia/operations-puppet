class profile::toolforge::k8s::kubeadm::master(
    Array[Stdlib::Fqdn] $etcd_hosts     = lookup('profile::toolforge::k8s::etcd_hosts'),
    Stdlib::Fqdn        $apiserver      = lookup('profile::toolforge::k8s::apiserver'),
    String              $node_token     = lookup('profile::toolforge::k8s::node_token'),
    Boolean             $existing_certs = lookup('profile::toolforge::k8s::existing_certs', { default_value => false})
) {
    require profile::toolforge::k8s::kubeadm::preflight_checks

    # use puppet certs to contact etcd
    $k8s_etcd_cert_pub  = "/etc/kubernetes/pki/puppet_${::fqdn}.pem"
    $k8s_etcd_cert_priv = "/etc/kubernetes/pki/puppet_${::fqdn}.priv"
    $k8s_etcd_cert_ca   = '/etc/kubernetes/pki/puppet_ca.pem'
    $puppet_cert_pub    = "/var/lib/puppet/ssl/certs/${::fqdn}.pem"
    $puppet_cert_priv   = "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem"
    $puppet_cert_ca     = '/var/lib/puppet/ssl/certs/ca.pem'

    file { '/etc/kubernetes/pki':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { $k8s_etcd_cert_pub:
        ensure => present,
        source => "file://${puppet_cert_pub}",
    }

    file { $k8s_etcd_cert_priv:
        ensure    => present,
        source    => "file://${puppet_cert_priv}",
        mode      => '0640',
        show_diff => false,
    }

    file { $k8s_etcd_cert_ca:
        ensure => present,
        source => "file://${puppet_cert_ca}",
    }

    class { 'toolforge::k8s::kubeadm': }

    $pod_subnet = '192.168.0.0/16'
    class { 'toolforge::k8s::kubeadm_init':
        etcd_hosts         => $etcd_hosts,
        apiserver          => $apiserver,
        pod_subnet         => $pod_subnet,
        node_token         => $node_token,
        k8s_etcd_cert_pub  => $k8s_etcd_cert_pub,
        k8s_etcd_cert_priv => $k8s_etcd_cert_priv,
        k8s_etcd_cert_ca   => $k8s_etcd_cert_ca,
    }

    class { 'toolforge::k8s::kubeadm_join':
        apiserver  => $apiserver,
        node_token => $node_token,
    }

    class { 'toolforge::k8s::kubeadm_calico':
        pod_subnet     => $pod_subnet,
    }

    # If there is an existing, bootstrapped control plane node, distribute certs from it
    if $existing_certs {
        file { '/etc/kubernetes/pki/ca.crt':
            content   => secret('toolforge/k8s/ca.crt'),
            require   => File['/etc/kubernetes/pki'],
            owner     => 'root',
            group     => 'root',
            mode      => '0444',
            show_diff => false,
        }

        file { '/etc/kubernetes/pki/ca.key':
            content   => secret('toolforge/k8s/ca.key'),
            require   => File['/etc/kubernetes/pki'],
            owner     => 'root',
            group     => 'root',
            mode      => '0400',
            show_diff => false,
        }

        file { '/etc/kubernetes/pki/sa.pub':
            content   => secret('toolforge/k8s/sa.pub'),
            require   => File['/etc/kubernetes/pki'],
            owner     => 'root',
            group     => 'root',
            mode      => '0400',
            show_diff => false,
        }

        file { '/etc/kubernetes/pki/sa.key':
            content   => secret('toolforge/k8s/sa.key'),
            require   => File['/etc/kubernetes/pki'],
            owner     => 'root',
            group     => 'root',
            mode      => '0400',
            show_diff => false,
        }

        file { '/etc/kubernetes/pki/front-proxy-ca.crt':
            content   => secret('toolforge/k8s/front-proxy-ca.crt'),
            require   => File['/etc/kubernetes/pki'],
            owner     => 'root',
            group     => 'root',
            mode      => '0444',
            show_diff => false,
        }

        file { '/etc/kubernetes/pki/front-proxy-ca.key':
            content   => secret('toolforge/k8s/front-proxy-ca.key'),
            require   => File['/etc/kubernetes/pki'],
            owner     => 'root',
            group     => 'root',
            mode      => '0400',
            show_diff => false,
        }

        file { '/etc/kubernetes/pki/etcd':
            ensure => directory,
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }

        file { '/etc/kubernetes/pki/etcd/ca.crt':
            content   => secret('toolforge/k8s/etcd-ca.crt'),
            require   => File['/etc/kubernetes/pki/etcd'],
            owner     => 'root',
            group     => 'root',
            mode      => '0444',
            show_diff => false,
        }

        file { '/etc/kubernetes/pki/etcd/ca.key':
            content   => secret('toolforge/k8s/etcd-ca.key'),
            require   => File['/etc/kubernetes/pki/etcd'],
            owner     => 'root',
            group     => 'root',
            mode      => '0400',
            show_diff => false,
        }
    }
}
