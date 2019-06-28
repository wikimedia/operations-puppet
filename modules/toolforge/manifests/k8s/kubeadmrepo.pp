class toolforge::k8s::kubeadmrepo(
) {
    apt::repository { 'toolforge-k8s-kubeadmrepo':
        uri        => 'http://apt.wikimedia.org/wikimedia/',
        dist       => 'stretch-wikimedia',
        components => 'thirdparty/kubeadm-k8s',
        source     => false,
        notify     => Exec['toolforge-k8s-kubeadmrepo-apt-update'],
    }

    # ensure apt can see the repo before any further Package[] declaration
    # so this proper repo/pinning configuration applies in the same puppet
    # agent run
    exec { 'toolforge-k8s-kubeadmrepo-apt-update':
        command     => '/usr/bin/apt-get update',
        require     => Apt::Repository['toolforge-k8s-kubeadmrepo'],
        subscribe   => Apt::Repository['toolforge-k8s-kubeadmrepo'],
        refreshonly => true,
        logoutput   => true,
    }
    Exec['toolforge-k8s-kubeadmrepo-apt-update'] -> Package <| |>
}
