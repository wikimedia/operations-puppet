# SPDX-License-Identifier: Apache-2.0
# Class that sets up and configures kube-proxy
class k8s::proxy (
    K8s::KubernetesVersion $version,
    String $kubeconfig,
    Boolean $masquerade_all,
    String $proxy_mode = 'iptables',
    Boolean $logtostderr = true,
    Integer $v_log_level = 0,
    Optional[String] $metrics_bind_address = undef,
    Optional[K8s::ClusterCIDR] $cluster_cidr = undef,
) {
    k8s::package { 'proxy':
        package => 'node',
        version => $version,
    }

    file { '/etc/default/kube-proxy':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('k8s/kube-proxy.default.erb'),
        notify  => Service['kube-proxy'],
    }

    service { 'kube-proxy':
        ensure    => running,
        enable    => true,
        subscribe => [
            File[$kubeconfig],
            File['/etc/default/kube-proxy'],
        ],
    }
}
