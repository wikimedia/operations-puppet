# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::kubeadm::client (
    String $component = lookup('profile::wmcs::kubeadm::component'),
) {
    class { '::kubeadm::repo':
        component => $component,
    }
    class { '::kubeadm::kubectl': }
}
