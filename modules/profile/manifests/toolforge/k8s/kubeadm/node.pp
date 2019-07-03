class profile::toolforge::k8s::kubeadm::node(
) {
    require profile::toolforge::k8s::kubeadm::preflight_checks

    class { 'toolforge::k8s::kubeadm': }

    # TODO: write the rest of the code :-)
}
