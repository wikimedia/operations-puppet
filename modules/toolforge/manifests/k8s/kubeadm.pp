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

    sysctl::parameters { 'kubelet':
        values   => {
            # Required by the protect-kernel-defaults option
            'vm.overcommit_memory' => 1,
            'kernel.panic'         => 10,
            'kernel.panic_on_oops' => 1,
        },
        priority => 90,
    }

    file { '/etc/default/kubelet':
        ensure  => 'present',
        mode    => '0444',
        content => @(ARGS/L),
        KUBELET_EXTRA_ARGS="--read-only-port=0 --protect-kernel-defaults=true\
         --tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE\
        _RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,\
        TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,\
        TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,\
        TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,\
        TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_GCM_SHA256 \
        --pod-infra-container-image=docker-registry.tools.wmflabs.org/pause:3.1\
        "
        |-ARGS
    }
}
