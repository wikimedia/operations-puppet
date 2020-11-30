class profile::wmcs::kubeadm::worker (
    String $component = lookup('profile::wmcs::kubeadm::component', {default_value => 'thirdparty/kubeadm-k8s-1-17'}),
) {
    require profile::wmcs::kubeadm::preflight_checks

    labs_lvm::volume { 'docker':
        mountat   => '/var/lib/docker',
        mountmode => '711',
        before    => Service['docker'],
    }

    class { '::kubeadm::repo':
        component => $component,
    }
    class { '::kubeadm::core': }
    class { '::kubeadm::calico_workaround': }
}
