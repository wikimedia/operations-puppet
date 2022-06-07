# SPDX-License-Identifier: Apache-2.0
class kubeadm::init_yaml (
    Stdlib::Fqdn                  $apiserver,
    String                        $pod_subnet,
    Boolean                       $stacked = false,
    Optional[Stdlib::Unixpath]    $k8s_etcd_cert_pub,
    Optional[Stdlib::Unixpath]    $k8s_etcd_cert_priv,
    Optional[Stdlib::Unixpath]    $k8s_etcd_cert_ca,
    Optional[Array[Stdlib::Fqdn]] $etcd_hosts,
    String                        $kubernetes_version = '1.20.11',
    String                        $node_token = undef,
    Optional[String]              $encryption_key = undef,
    Optional[Integer]             $etcd_heartbeat_interval = undef,
    Optional[Integer]             $etcd_election_timeout = undef,
    Optional[Integer]             $etcd_snapshot_ct = undef,
    Array[Stdlib::Fqdn]           $apiserver_cert_alternative_names = [],
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

    file { '/etc/kubernetes/admission':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        require => File['/etc/kubernetes'],
    }

        file { '/etc/kubernetes/admission/admission.yaml':
        ensure  => present,
        source  => 'puppet:///modules/kubeadm/admission.yaml',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/etc/kubernetes/admission'],
    }

    file { '/etc/kubernetes/admission/eventconfig.yaml':
        ensure  => present,
        source  => 'puppet:///modules/kubeadm/eventconfig.yaml',
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
            content   => template('kubeadm/encryption-conf.yaml.erb'),
            owner     => 'root',
            group     => 'root',
            mode      => '0400',
            require   => File['/etc/kubernetes/admission'],
            show_diff => false,
        }
    }
}
