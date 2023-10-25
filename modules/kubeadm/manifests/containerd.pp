# SPDX-License-Identifier: Apache-2.0
# @summary install and configure containerd for toolforge k8s usage
class kubeadm::containerd () {
  package { 'containerd':
    ensure => installed,
  }

  service { 'containerd':
    ensure => running,
  }
}
