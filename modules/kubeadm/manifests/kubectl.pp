class kubeadm::kubectl (
) {
    require ::kubeadm::repo

    package  { 'kubectl':
        ensure => 'present',
        tag    => 'kubeadm-k8s',
    }
}
