class profile::wmcs::kubeadm::client (
    String $component = lookup('profile::wmcs::kubeadm::component', {default_value => 'thirdparty/kubeadm-k8s-1-21'}),
) {
    class { '::kubeadm::repo':
        component => $component,
    }
    class { '::kubeadm::kubectl': }
}
