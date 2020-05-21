class profile::wmcs::paws::k8s::control (
) {
    require_package('helm3') # this package lives in buster-wikimedia/main

    class { '::profile::wmcs::kubeadm::control': }
    contain '::profile::wmcs::kubeadm::control'
}
