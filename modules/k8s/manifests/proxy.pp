# SPDX-License-Identifier: Apache-2.0
# Class that sets up and configures kube-proxy
class k8s::proxy (
    K8s::KubernetesVersion $version,
    Stdlib::Unixpath $kubeconfig,
    Optional[K8s::ClusterCIDR] $cluster_cidr = undef,
    Boolean $ipv6dualstack = false,
    Enum['iptables', 'ipvs'] $proxy_mode = 'iptables',
    Optional[K8s::KubeProxyDetectLocal] $detect_local = undef,
    Integer $v_log_level = 0,
) {
    k8s::package { 'proxy':
        package => 'node',
        version => $version,
    }

    # kube-proxy uses detectLocalMode to identify traffic from a Pod on this
    # node. It does not masquerade that traffic, so the destination Pod sees the
    # real client address. The default mode, ClusterCIDR, compares the source
    # address with clusterCIDR, and thus permits only one Pod range per IP
    # family. See K8s::KubeProxyDetectLocal and T429773.
    $_detect_local_mode = $detect_local ? {
        undef   => 'ClusterCIDR',
        default => $detect_local['mode'],
    }

    # kube-proxy does not fail if it runs in ClusterCIDR mode with no
    # clusterCIDR. It installs a no-op detector, treats no traffic as local and
    # masquerades every connection to a Service. Fail the catalog instead.
    if $_detect_local_mode == 'ClusterCIDR' and $cluster_cidr =~ Undef {
        fail('k8s::proxy: cluster_cidr is mandatory unless detect_local selects another mode')
    }

    # Only the ClusterCIDR mode reads clusterCIDR. Leave it undef in the other
    # modes. The filter below then removes the key, so the file does not show a
    # Pod range that nothing uses.
    $_clustercidr = $_detect_local_mode ? {
        'ClusterCIDR' => $ipv6dualstack ? {
            true  => "${cluster_cidr['v4']},${cluster_cidr['v6']}",
            false => $cluster_cidr['v4'],
        },
        default       => undef,
    }

    # Create the KubeProxyConfiguration YAML
    $base_config_yaml = {
        apiVersion         => 'kubeproxy.config.k8s.io/v1alpha1',
        kind               => 'KubeProxyConfiguration',
        hostnameOverride   => $facts['networking']['fqdn'],
        clientConnection   => { kubeconfig => $kubeconfig },
        clusterCIDR        => $_clustercidr,
        mode               => $proxy_mode,
        metricsBindAddress => '0.0.0.0',
    }

    # Write detectLocalMode and detectLocal only if a mode is selected.
    # An empty detectLocal hash is removed again by the filter below.
    $detect_local_yaml = $detect_local ? {
        undef   => {},
        default => {
            detectLocalMode => $detect_local['mode'],
            detectLocal     => {
                'bridgeInterface'     => $detect_local['bridge_interface'],
                'interfaceNamePrefix' => $detect_local['interface_name_prefix'],
            }.filter |$k, $v| { $v =~ NotUndef },
        },
    }

    # Additional KubeProxyConfiguration parameters since 1.31
    $config_yaml = $base_config_yaml.merge($detect_local_yaml).merge({
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
