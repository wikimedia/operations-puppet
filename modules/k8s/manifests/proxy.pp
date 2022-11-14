# SPDX-License-Identifier: Apache-2.0
# Class that sets up and configures kube-proxy
class k8s::proxy (
    K8s::KubernetesVersion $version,
    Stdlib::Unixpath $kubeconfig,
    K8s::ClusterCIDR $cluster_cidr,
    Boolean $ipv6dualstack = false,
    Enum['iptables', 'ipvs'] $proxy_mode = 'iptables',
    Boolean $logtostderr = true,
    Integer $v_log_level = 0,
) {
    k8s::package { 'proxy':
        package => 'node',
        version => $version,
    }

    # IPv6 is an alpha feature on 1.16 and needs a variety of tunables
    # (https://kubernetes.io/docs/concepts/services-networking/dual-stack/) to
    # fully work.
    # We are on purpose NOT adding support for IPv6 feature gate for kube-proxy as
    # the feature is alpha grade and not deemed stable yet on our version.
    # We DO currently only enable it for kubelet, see I54a042731f60dc02494907022cb8115fae052c50
    $_clustercidr = ($ipv6dualstack and versioncmp($version, '1.23') >= 0) ? {
        true  => "${cluster_cidr['v4']},${cluster_cidr['v6']}",
        false => $cluster_cidr['v4'],
    }

    # Create the KubeProxyConfiguration YAML
    $config_yaml = {
        apiVersion         => 'kubeproxy.config.k8s.io/v1alpha1',
        kind               => 'KubeProxyConfiguration',
        hostnameOverride   => $facts['fqdn'],
        clientConnection   => { kubeconfig => $kubeconfig },
        clusterCIDR        => $_clustercidr,
        mode               => $proxy_mode,
        metricsBindAddress => '0.0.0.0',
    }
    $config_file = '/etc/kubernetes/kube-proxy-config.yaml'
    file { $config_file:
        ensure  => file,
        owner   => 'kube',
        group   => 'kube',
        mode    => '0400',
        content => $config_yaml.filter |$k, $v| { $v =~ NotUndef and !$v.empty }.to_yaml,
        notify  => Service['kube-proxy'],
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
