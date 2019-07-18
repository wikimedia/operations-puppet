class profile::toolforge::k8s::kubeadm::node(
    Stdlib::Fqdn $apiserver  = lookup('profile::toolforge::k8s::apiserver'),
    String       $node_token = lookup('profile::toolforge::k8s::node_token'),
) {
    require profile::toolforge::k8s::kubeadm::preflight_checks

    class { 'toolforge::k8s::kubeadm': }

    class { 'toolforge::k8s::kubeadm_join':
        apiserver  => $apiserver,
        node_token => $node_token,
    }

    class { '::toolforge::k8s::kubeadm_calico_workaround': }
}
