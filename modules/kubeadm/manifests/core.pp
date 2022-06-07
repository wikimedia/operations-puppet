# SPDX-License-Identifier: Apache-2.0
# main kubeadm packages and setup
class kubeadm::core (
) {
    require ::kubeadm::repo
    include ::kubeadm::kubectl

    $packages = [
        'kubeadm',
        'kubernetes-cni',
        'containerd.io',
        'cri-tools',
        'ipset',
    ]

    package { $packages:
        ensure => 'present',
        tag    => 'kubeadm-k8s',
    }

    class { 'k8s::base_dirs': }

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
        notify  => Service['kubelet'],
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

    # If kubelet is failing, there's no notice offered by kubernetes directly
    # the node can still show "ready" in some situations (?!?).
    service { 'kubelet':
        ensure => 'running'
    }
}
