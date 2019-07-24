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
        'ipset',
    ]

    package { $packages:
        ensure => 'present',
    }

    file { '/etc/kubernetes/':
        ensure => 'directory',
    }

    include ::toolforge::k8s::kubeadm_docker_service

    file { '/etc/default/kubelet':
        ensure  => 'present',
        mode    => '0444',
        content => 'KUBELET_EXTRA_ARGS="--pod-infra-container-image=docker-registry.tools.wmflabs.org/pause:3.1"'
    }
}
