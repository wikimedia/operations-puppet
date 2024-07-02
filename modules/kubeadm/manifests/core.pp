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
        $extra_labels_joined = "--node-labels='${extra_labels.join(',')}'"
    } else {
        $extra_labels_joined = ''
    }

    if $extra_labels_joined == '' {
        file { '/etc/default/kubelet':
            ensure => 'absent',
            notify => Service['kubelet'],
        }
    } else {
        file { '/etc/default/kubelet':
            ensure  => 'present',
            mode    => '0444',
            notify  => Service['kubelet'],
            content => "KUBELET_EXTRA_ARGS=\"${extra_labels_joined}\"\n",
        }
    }

    # If kubelet is failing, there's no notice offered by kubernetes directly
    # the node can still show "ready" in some situations (?!?).
    service { 'kubelet':
        ensure => 'running'
    }
}
