class profile::wmcs::kubeadm::client (
    String $component = lookup('profile::wmcs::kubeadm::component', {default_value => 'thirdparty/kubeadm-k8s-1-18'}),
) {
    class { '::kubeadm::repo':
        component => $component,
    }
    class { '::kubeadm::kubectl': }
}
