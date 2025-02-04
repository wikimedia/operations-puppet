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

    class { '::base::sysctl::inotify':
        max_user_watches   => 32768,
        max_user_instances => 1024,
    }
    # clean up previous incarnation of the above
    sysctl::parameters { 'extra_inotify_instances':
        ensure => absent,
        values => {
            'fs.inotify.max_user_watches'   => 32768,
            'fs.inotify.max_user_instances' => 1024,
        },
    }

    include ::profile::wmcs::kubeadm::core
    contain ::profile::wmcs::kubeadm::core
}
