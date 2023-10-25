# SPDX-License-Identifier: Apache-2.0
# @summary install and configure containerd for toolforge k8s usage
class kubeadm::containerd (
  String[1] $pause_image,
) {
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

  file { '/etc/containerd/config.toml':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('kubeadm/containerd/containerd.toml.erb'),
    notify  => Service['containerd'],
  }

  service { 'containerd':
    ensure => running,
  }
}
