class profile::toolforge::k8s::client () {
    class { '::profile::wmcs::kubeadm::client': }
    contain '::profile::wmcs::kubeadm::client'
}
