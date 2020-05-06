class profile::wmcs::kubeadm::client (
) {
    class { '::kubeadm::kubectl': }
}
