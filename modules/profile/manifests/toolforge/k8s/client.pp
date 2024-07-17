class profile::toolforge::k8s::client () {
    class { '::profile::wmcs::kubeadm::client': }
    -> class { '::kubeadm::helm': }
    contain '::profile::wmcs::kubeadm::client'
}
