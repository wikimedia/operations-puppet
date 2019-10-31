class profile::toolforge::k8s::worker (
) {
    require profile::toolforge::k8s::preflight_checks

    class { '::toolforge::k8s::kubeadm': }
    class { '::toolforge::k8s::calico_workaround': }
}
