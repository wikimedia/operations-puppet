class profile::toolforge::k8s::worker (
) {
    class { '::profile::wmcs::kubeadm::worker': }
    contain '::profile::wmcs::kubeadm::worker'
}
