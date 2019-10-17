class profile::toolforge::k8s::node(
) {
    require profile::toolforge::k8s::preflight_checks

    class { '::toolforge::k8s::kubeadm': }
    class { '::toolforge::k8s::kubeadm_calico_workaround': }
}
