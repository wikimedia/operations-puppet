# SPDX-License-Identifier: Apache-2.0
class kubeadm::calico_workaround (
) {
    alternatives::select { 'iptables':
        path    => '/usr/sbin/iptables-legacy',
        require => Package['docker-ce'], # iptables is a docker-ce depedency
    }
    alternatives::select { 'ip6tables':
        path    => '/usr/sbin/ip6tables-legacy',
        require => Package['docker-ce'], # iptables is a docker-ce dependency
    }
    alternatives::select { 'ebtables':
        path    => '/usr/sbin/ebtables-legacy',
        require => Package['kubeadm'],   # ebtables is a kubelet dependency, which is a kubeadm dep
    }
}
