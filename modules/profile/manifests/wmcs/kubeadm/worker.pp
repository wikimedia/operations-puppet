class profile::wmcs::kubeadm::worker (
) {
    require profile::wmcs::kubeadm::preflight_checks

    labs_lvm::volume { 'docker':
        mountat   => '/var/lib/docker',
        mountmode => '711',
        before    => Service['docker'],
    }

    class { '::kubeadm::core': }
    class { '::kubeadm::calico_workaround': }
}
