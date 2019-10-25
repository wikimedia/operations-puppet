class profile::ceph::k8s::control(
    Array[Stdlib::Fqdn] $etcd_hosts         = lookup('profile::ceph::mon_hosts'),
    Stdlib::Fqdn        $apiserver          = lookup('profile::ceph::k8s::apiserver'),
    String              $kubernetes_version = lookup('profile::ceph::k8s::version'),
    String              $node_token         = lookup('profile::ceph::k8s::node_token'),
    String              $pause_image        = lookup('profile::ceph::k8s::pause_image'),
    Stdlib::IP::Address $pod_subnet         = lookup('profile::ceph::k8s::pod_subnet'),
) {
    class { 'ceph::k8s::kubeadm_config':
        apiserver          => $apiserver,
        etcd_hosts         => $etcd_hosts,
        kubernetes_version => $kubernetes_version,
        node_token         => $node_token,
        pause_image        => $pause_image,
        pod_subnet         => $pod_subnet,
    }

    class { 'ceph::k8s::calico':
        pod_subnet => $pod_subnet,
    }

    class { 'ceph::rook': }
}
