# SPDX-License-Identifier: Apache-2.0
# @summary install and configure containerd for toolforge k8s usage
class kubeadm::containerd () {
  kmod::module { 'br_netfilter':
    ensure => 'present',
  }

  sysctl::parameters { 'kubernetes-ip-forward':
    values => {
      'net.ipv4.ip_forward' => 1,
    },
  }

  package { 'containerd':
    ensure => installed,
  }

  service { 'containerd':
    ensure => running,
  }
}
