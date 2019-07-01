class toolforge::k8s::kubeadm(
) {
    require ::toolforge::k8s::kubeadmrepo

    $packages = [
        'kubeadm',
        'kubectl',
        'kubernetes-cni',
        'docker-ce',
        'docker-ce-cli',
        'containerd.io',
        'cri-tools',
    ]

    package { $packages:
        ensure => 'present',
    }

}
