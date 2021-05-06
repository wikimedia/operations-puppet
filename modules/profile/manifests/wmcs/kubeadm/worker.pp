class profile::wmcs::kubeadm::worker (
    String $component = lookup('profile::wmcs::kubeadm::component', {default_value => 'thirdparty/kubeadm-k8s-1-17'}),
    Boolean $docker_vol = lookup('profile::wmcs::kubeadm::docker_vol', {default_value => true}),
) {
    require profile::wmcs::kubeadm::preflight_checks

    if $docker_vol {
        cinderutils::ensure { 'separate-docker':
            min_gb        => 40,
            max_gb        => 160,
            mount_point   => '/var/lib/docker',
            mount_mode    => '711',
            mount_options => 'discard,defaults',
            before        => Service['docker'],
        }
    }

    class { '::kubeadm::repo':
        component => $component,
    }
    class { '::kubeadm::core': }
    class { '::kubeadm::calico_workaround': }
}
