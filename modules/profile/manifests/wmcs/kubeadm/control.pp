# SPDX-License-Identifier: Apache-2.0
# Note: To bootstrap a cluster $kubernetes_version must match the version of packages
# in the $component
class profile::wmcs::kubeadm::control (
    Boolean             $stacked_control_plane = lookup('profile::wmcs::kubeadm::stacked', {default_value => false}),
    Array[Stdlib::Fqdn] $etcd_hosts = lookup('profile::wmcs::kubeadm::etcd_nodes',     {default_value => ['localhost']}),
    Stdlib::Fqdn        $apiserver  = lookup('profile::wmcs::kubeadm::apiserver_fqdn', {default_value => 'k8s.example.com'}),
    String              $node_token = lookup('profile::wmcs::kubeadm::node_token',     {default_value => 'example.token'}),
    String              $kubernetes_version = lookup('profile::wmcs::kubeadm::kubernetes_version', {default_value => '1.21.8'}),
    String              $calico_version = lookup('profile::wmcs::kubeadm::calico_version', {default_value => 'v3.21.0'}),
    Boolean             $typha_enabled = lookup('profile::wmcs::kubeadm::typha_enabled', {default_value => false}),
    Integer             $typha_replicas = lookup('profile::wmcs::kubeadm::typha_replicas', {default_value => 3}),
    Optional[String]    $encryption_key = lookup('profile::wmcs::kubeadm::encryption_key', {default_value => undef}),
    Optional[Integer]   $etcd_heartbeat_interval = lookup('profile::wmcs::kubeadm::etcd_heartbeat_interval', {default_value => undef}),
    Optional[Integer]   $etcd_election_timeout = lookup('profile::wmcs::kubeadm::etcd_election_timeout', {default_value => undef}),
    Optional[Integer]   $etcd_snapshot_ct = lookup('profile::wmcs::kubeadm::etcd_snapshot_ct', {default_value => undef}),
    Array[Stdlib::Fqdn] $apiserver_cert_alternative_names = lookup('profile::wmcs::kubeadm::control::apiserver_cert_alternative_names', {default_value => []}),
) {
    require profile::wmcs::kubeadm::preflight_checks

    # use puppet certs to contact etcd
    $k8s_etcd_cert_pub  = '/etc/kubernetes/pki/puppet_etcd_client.crt'
    $k8s_etcd_cert_priv = '/etc/kubernetes/pki/puppet_etcd_client.key'
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

    if ! $stacked_control_plane {
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
    }

    file { '/srv/git':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',

    }

    git::clone { 'labs/tools/maintain-kubeusers':
        ensure    => present,
        directory => '/srv/git/maintain-kubeusers',
    }

    include ::profile::wmcs::kubeadm::core
    contain ::profile::wmcs::kubeadm::core

    class { '::kubeadm::helm': }

    # TODO: eventually we may need overriding this CIDR
    $pod_subnet = '192.168.0.0/16'
    class { '::kubeadm::init_yaml':
        stacked                          => $stacked_control_plane,
        etcd_hosts                       => $etcd_hosts,
        apiserver                        => $apiserver,
        pod_subnet                       => $pod_subnet,
        node_token                       => $node_token,
        k8s_etcd_cert_pub                => $k8s_etcd_cert_pub,
        k8s_etcd_cert_priv               => $k8s_etcd_cert_priv,
        k8s_etcd_cert_ca                 => $k8s_etcd_cert_ca,
        encryption_key                   => $encryption_key,
        kubernetes_version               => $kubernetes_version,
        etcd_heartbeat_interval          => $etcd_heartbeat_interval,
        etcd_election_timeout            => $etcd_election_timeout,
        etcd_snapshot_ct                 => $etcd_snapshot_ct,
        apiserver_cert_alternative_names => $apiserver_cert_alternative_names,
    }

    class { '::kubeadm::calico_yaml':
        pod_subnet     => $pod_subnet,
        calico_version => $calico_version,
        typha_enabled  => $typha_enabled,
        typha_replicas => $typha_replicas,
    }

    class { '::kubeadm::admin_scripts': }

    class { '::kubeadm::metrics_yaml': }
}
