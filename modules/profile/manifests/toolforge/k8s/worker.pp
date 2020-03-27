class profile::toolforge::k8s::worker (
) {
    require profile::toolforge::k8s::preflight_checks

    labs_lvm::volume { 'docker':
        mountat   => '/var/lib/docker',
        mountmode => '711',
        before    => Service['docker'],
    }

    class { '::toolforge::k8s::kubeadm': }
    class { '::toolforge::k8s::calico_workaround': }
}
