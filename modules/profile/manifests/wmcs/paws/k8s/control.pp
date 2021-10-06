class profile::wmcs::paws::k8s::control (
) {
    ensure_packages('helm3') # this package lives in buster-wikimedia/main

    class { '::profile::wmcs::kubeadm::control': }
    contain '::profile::wmcs::kubeadm::control'

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
