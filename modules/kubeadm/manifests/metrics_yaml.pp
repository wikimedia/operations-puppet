# SPDX-License-Identifier: Apache-2.0
class kubeadm::metrics_yaml () {
    # Now served from a separate gitlab repository and deployed using the
    # wmcs.toolforge.k8s.component.deploy cookbook.
    # https://gitlab.wikimedia.org/repos/cloud/toolforge/kubernetes-metrics

    file { '/etc/kubernetes/metrics/':
        ensure  => absent,
        recurse => true,
        force   => true,
    }
}
