# SPDX-License-Identifier: Apache-2.0
# main kubeadm packages and setup
class kubeadm::core (
    String[1]     $pause_image,
    Array[String] $extra_labels,
) {
    require ::kubeadm::repo
    include ::kubeadm::kubectl

    $packages = [
        'kubeadm',
        'kubernetes-cni',
        'cri-tools',
        'ipset',
    ]

    package { $packages:
        ensure => 'present',
        tag    => 'kubeadm-k8s',
    }

    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    sysctl::parameters { 'kubelet':
        values   => {
            # Required by the protect-kernel-defaults option
            'vm.overcommit_memory' => 1,
            'kernel.panic'         => 10,
            'kernel.panic_on_oops' => 1,
        },
        priority => 90,
    }

    if $extra_labels != [] {
        $extra_labels_joined = " --node-labels='${extra_labels.join(',')}'"
    } else {
        $extra_labels_joined = ''
    }

    file { '/etc/default/kubelet':
        ensure  => 'present',
        mode    => '0444',
        notify  => Service['kubelet'],
        content => @("ARGS"/L),
        KUBELET_EXTRA_ARGS="--read-only-port=0 --protect-kernel-defaults=true\
         --tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE\
        _RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,\
        TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,\
        TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,\
        TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,\
        TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_GCM_SHA256 \
        --pod-infra-container-image=${pause_image}\
        ${extra_labels_joined}\
        "
        |-ARGS
    }

    # If kubelet is failing, there's no notice offered by kubernetes directly
    # the node can still show "ready" in some situations (?!?).
    service { 'kubelet':
        ensure => 'running'
    }
}
