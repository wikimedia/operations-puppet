class toolforge::k8s::kubeadmrepo(
) {
    # TODO:
    # a future patch will wipe this class and use apt::package_from_component
    # from the calling manifests instead
    #

    apt::pin { 'toolforge-k8s-kubeadmrepo-core':
        package  => 'kubeadm kubelet kubectl',
        pin      => 'version 1.15.6-00',
        priority => '1001',
    }
    apt::pin { 'toolforge-k8s-kubeadmrepo-kubernetes-cni':
        package  => 'kubernetes-cni',
        pin      => 'version 0.7.5-00',
        priority => '1001',
    }
    apt::pin { 'toolforge-k8s-kubeadmrepo-cri-tools':
        package  => 'cri-tools',
        pin      => 'version 1.13.0-00',
        priority => '1001',
    }
    apt::pin { 'toolforge-k8s-kubeadmrepo-docker':
        package  => 'docker-ce docker-ce-cli',
        pin      => 'version 5:19.03.5~3-0~debian-stretch',
        priority => '1001',
    }
    apt::pin { 'toolforge-k8s-kubeadmrepo-containerd':
        package  => 'containerd.io',
        pin      => 'version 1.2.10-3',
        priority => '1001',
    }

    apt::repository { 'toolforge-k8s-kubeadmrepo':
        uri        => 'http://apt.wikimedia.org/wikimedia/',
        dist       => 'buster-wikimedia',
        components => 'thirdparty/kubeadm-k8s-1-15',
        source     => false,
        notify     => Exec['toolforge-k8s-kubeadmrepo-apt-update'],
    }

    # ensure apt can see the repo before any further Package[] declaration
    # so this proper repo/pinning configuration applies in the same puppet
    # agent run
    exec { 'toolforge-k8s-kubeadmrepo-apt-update':
        command     => '/usr/bin/apt-get update',
        subscribe   => Apt::Repository['toolforge-k8s-kubeadmrepo'],
        refreshonly => true,
        logoutput   => true,
    }
    Exec['toolforge-k8s-kubeadmrepo-apt-update'] -> Package <| |>
}
