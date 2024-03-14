# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::kubeadm::worker (
    Boolean $docker_vol = lookup('profile::wmcs::kubeadm::docker_vol', {default_value => true}),
) {
    require profile::wmcs::kubeadm::preflight_checks

    # TODO: rename variable
    if $docker_vol {
        cinderutils::ensure { 'separate-containerd':
            min_gb        => 40,
            max_gb        => 160,
            mount_point   => '/var/lib/containerd',
            mount_mode    => '711',
            mount_options => 'discard,defaults',
            before        => Service['containerd'],
        }
    }

    include ::profile::wmcs::kubeadm::core
    contain ::profile::wmcs::kubeadm::core
}
