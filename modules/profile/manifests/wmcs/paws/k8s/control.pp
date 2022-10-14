# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::paws::k8s::control (
) {
    class { '::profile::wmcs::kubeadm::control': }
    contain '::profile::wmcs::kubeadm::control'

    # To avoid confusion, we use the same helm binary that Toolforge
    # uses, which is imported to the kubeadm component from upstream
    # repositories directly (named helm, not helm3), instead of using
    # the packages WMF's serviceops team builds locally.
    package { 'helm3':
        ensure => absent,
    }

    # To facilitate deploying manifests directly from the repo to k8s.
    # This would allow paws admins more flexibility for k8s-controlled elements
    git::clone { 'paws-git':
        ensure    => 'latest',
        directory => '/srv/git/paws',
        branch    => 'master',
        origin    => 'https://github.com/toolforge/paws.git'
    }

    labs_lvm::volume { 'docker':
        size      => '60%FREE',
        mountat   => '/var/lib/docker',
        mountmode => '711',
    } -> labs_lvm::volume { 'etcd-disk':
        mountat => '/var/lib/etcd',
    }
}
