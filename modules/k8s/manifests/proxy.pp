# SPDX-License-Identifier: Apache-2.0
# Class that sets up and configures kube-proxy
class k8s::proxy (
    K8s::KubernetesVersion $version,
    Stdlib::Unixpath $kubeconfig,
    K8s::ClusterCIDR $cluster_cidr,
    Boolean $ipv6dualstack = false,
    Enum['iptables', 'ipvs'] $proxy_mode = 'iptables',
    Integer $v_log_level = 0,
) {
    k8s::package { 'proxy':
        package => 'node',
        version => $version,
    }

    $_clustercidr = $ipv6dualstack ? {
        true  => "${cluster_cidr['v4']},${cluster_cidr['v6']}",
        false => $cluster_cidr['v4'],
    }

    # Create the KubeProxyConfiguration YAML
    $base_config_yaml = {
        apiVersion         => 'kubeproxy.config.k8s.io/v1alpha1',
        kind               => 'KubeProxyConfiguration',
        hostnameOverride   => $facts['fqdn'],
        clientConnection   => { kubeconfig => $kubeconfig },
        clusterCIDR        => $_clustercidr,
        mode               => $proxy_mode,
        metricsBindAddress => '0.0.0.0',
    }

    # Additional KubeProxyConfiguration parameters since 1.31
    $config_yaml = $base_config_yaml.merge({
        # Connections to NodePort services will only be accepted on node IPs in one of
        # the indicated ranges.In any mode but nftables, connections are accepted on
        # any node IP. In nftables mode, only connections to the primary node IPs
        # (according to the Node object) are accepted. So we explicitly define this
        # here in order to avoid confusion in the future.
        nodePortAddresses => ['0.0.0.0/0','::/0'],
    })

    $config_file = '/etc/kubernetes/kube-proxy-config.yaml'
    file { $config_file:
        ensure  => file,
        owner   => 'kube',
        group   => 'kube',
        mode    => '0400',
        content => $config_yaml.filter |$k, $v| { $v =~ NotUndef and !$v.empty }.to_yaml,
        notify  => Service['kube-proxy'],
        require => K8s::Package['proxy'],
    }

    file { '/etc/default/kube-proxy':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('k8s/kube-proxy.default.erb'),
        notify  => Service['kube-proxy'],
    }

    systemd::service { 'kube-proxy':
        ensure    => present,
        restart   => true,
        override  => true,
        content   => "[Unit]\nAfter = ferm.service",
        subscribe => File[$kubeconfig],
    }
}
