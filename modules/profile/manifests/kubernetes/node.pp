class profile::kubernetes::node (
    Stdlib::Fqdn $master_fqdn = lookup('profile::kubernetes::master_fqdn'),
    Array[Stdlib::Host] $master_hosts = lookup('profile::kubernetes::master_hosts'),
    String $infra_pod = lookup('profile::kubernetes::infra_pod'),
    Boolean $use_cni = lookup('profile::kubernetes::use_cni'),
    Boolean $masquerade_all = lookup('profile::kubernetes::node::masquerade_all', { default_value => true }),
    Stdlib::Unixpath $kubelet_config = lookup('profile::kubernetes::node::kubelet_config', { default_value => '/etc/kubernetes/kubelet_config' }),
    Stdlib::Unixpath $kubeproxy_config = lookup('profile::kubernetes::node::kubeproxy_config', { default_value => '/etc/kubernetes/kubeproxy_config' }),
    Stdlib::Httpurl $prometheus_url   = lookup('profile::kubernetes::node::prometheus_url', { default_value => "http://prometheus.svc.${::site }.wmnet/k8s" }),
    String $kubelet_cluster_domain = lookup('profile::kubernetes::node::kubelet_cluster_domain', { default_value => 'kube' }),
    Optional[Stdlib::IP::Address] $kubelet_cluster_dns = lookup('profile::kubernetes::node::kubelet_cluster_dns', { default_value => undef }),
    String $kubelet_username = lookup('profile::kubernetes::node::kubelet_username', { default_value => 'kubelet' }),
    String $kubelet_token = lookup('profile::kubernetes::node::kubelet_token'),
    Optional[Array[String]] $kubelet_extra_params = lookup('profile::kubernetes::node::kubelet_extra_params', { default_value => undef }),
    Optional[Array[String]] $kubelet_node_labels = lookup('profile::kubernetes::node::kubelet_node_labels', { default_value => [] }),
    Optional[Array[String]] $kubelet_node_taints = lookup('profile::kubernetes::node::kubelet_node_taints', { default_value => [] }),
    String $kubeproxy_username = lookup('profile::kubernetes::node::kubeproxy_username', { default_value => 'system:kube-proxy' }),
    String $kubeproxy_token = lookup('profile::kubernetes::node::kubeproxy_token'),
    Boolean $packages_from_future = lookup('profile::kubernetes::node::packages_from_future', { default_value => false }),
    Optional[String] $kubeproxy_metrics_bind_address = lookup('profile::kubernetes::node::kubeproxy_metrics_bind_address', { default_value => undef }),
    Boolean $kubelet_ipv6 = lookup('profile::kubernetes::node::kubelet_ipv6', { default_value => false }),
    Optional[String] $docker_kubernetes_user_password = lookup('profile::kubernetes::node::docker_kubernetes_user_password', { default_value => undef }),
    Optional[K8s::ClusterCIDR] $cluster_cidr = lookup('profile::kubernetes::cluster_cidr', { default_value => undef }),
) {
    require ::profile::rsyslog::kubernetes

    rsyslog::input::file { 'kubernetes-json':
        path               => '/var/log/containers/*.log',
        reopen_on_truncate => 'on',
        addmetadata        => 'on',
        addceetag          => 'on',
        syslog_tag         => 'kubernetes',
        priority           => 8,
    }

    # Note: this will also install /etc/kubernetes
    k8s::kubeconfig { $kubelet_config:
        master_host => $master_fqdn,
        username    => $kubelet_username,
        token       => $kubelet_token,
    }

    # TODO: consider using profile::pki::get_cert
    puppet::expose_agent_certs { '/etc/kubernetes':
        provide_private => true,
        user            => 'root',
        group           => 'root',
    }

    # Figure out if this node has SSD or spinning disks
    # This is not the absolute correct approach, but it will do for now
    if $facts['is_virtual'] {
        # disk_type will be "kvm" for example
        $disk_type = $facts['virtual']
    } else {
        $ssd_disks = filter($facts['disk_type']) |$x| {
            $x[1] == 'ssd'
        }
        if $ssd_disks.length > 0 {
            $disk_type = 'ssd'
        } else {
            $disk_type = 'hdd'
        }
    }

    # On Debian Bullseye the unified cgroup hierarchy is turned on
    # by default, and it is the only one available.
    # Kubelet on 1.16 doesn't support it, so we need to revert
    # the behavior to what was available on Buster
    # (until we upgrade to k8s 1.2x).
    if debian::codename::eq('bullseye') {
        grub::bootparam { 'disable_unified_cgroup_hierarchy':
            key   => 'systemd.unified_cgroup_hierarchy',
            value => '0',
        }
    }

    $node_labels = concat($kubelet_node_labels, "node.kubernetes.io/disk-type=${disk_type}")
    class { 'k8s::kubelet':
        listen_address                  => '0.0.0.0',
        cni                             => $use_cni,
        cluster_domain                  => $kubelet_cluster_domain,
        cluster_dns                     => $kubelet_cluster_dns,
        pod_infra_container_image       => $infra_pod,
        tls_cert                        => '/etc/kubernetes/ssl/cert.pem',
        tls_key                         => '/etc/kubernetes/ssl/server.key',
        kubeconfig                      => $kubelet_config,
        node_labels                     => $node_labels,
        node_taints                     => $kubelet_node_taints,
        extra_params                    => $kubelet_extra_params,
        packages_from_future            => $packages_from_future,
        kubelet_ipv6                    => $kubelet_ipv6,
        docker_kubernetes_user_password => $docker_kubernetes_user_password,
    }

    k8s::kubeconfig { $kubeproxy_config:
        master_host => $master_fqdn,
        username    => $kubeproxy_username,
        token       => $kubeproxy_token,
    }
    class { 'k8s::proxy':
        masquerade_all       => $masquerade_all,
        metrics_bind_address => $kubeproxy_metrics_bind_address,
        kubeconfig           => $kubeproxy_config,
        packages_from_future => $packages_from_future,
        cluster_cidr         => $cluster_cidr,
    }

    # Set the host as a router for IPv6 in order to allow pods to have an IPv6
    # address
    # If the host considers itself as a router (IP forwarding enabled), it will
    # ignore all router advertisements, breaking IPv6 SLAAC. Accept Router
    # Advertisements even if forwarding is enabled, but only on the primary
    # interface
    # lint:ignore:arrow_alignment
    sysctl::parameters { 'ipv6-fowarding-accept-ra':
        values => {
            'net.ipv6.conf.all.forwarding' => 1,
            "net.ipv6.conf.${facts['interface_primary']}.accept_ra" => 2,
        },
    }
    # lint:endignore

    $master_hosts_ferm = join($master_hosts, ' ')
    ferm::service { 'kubelet-http':
        proto  => 'tcp',
        port   => '10250',
        srange => "(@resolve((${master_hosts_ferm})) @resolve((${master_hosts_ferm}), AAAA))",
    }

    # kube-proxy on startup sets the following. However sysctl values may be
    # changed after that. Enforce them in puppet as well to avoid nasty
    # surprises. Furthermore, since we don't want our kubernetes nodes, which
    # act as routers, to send ICMP redirects to other nodes when reached for
    # workloads that don't reside on them but do know the router for, disable
    # send_redirects. T226237
    sysctl::parameters { 'kube_proxy_conntrack':
        values   => {
            'net.netfilter.nf_conntrack_max'                             => 1048576,
            'net.ipv4.conf.all.send_redirects'                           => 0,
            'net.ipv4.conf.default.send_redirects'                       => 0,
            "net.ipv4.conf.${facts['interface_primary']}.send_redirects" => 0,
        },
        priority => 75,
    }

    # Context:
    # https://phabricator.wikimedia.org/T287238
    # issue: https://github.com/kubernetes/kubernetes/issues/82361
    # fix for k8s 1.17+: https://github.com/kubernetes/kubernetes/pull/81517
    # Note:
    # For Bullseye this is not needed anymore, we set iptables-legacy via ferm's
    # defaults and the Debian upstream version of iptables
    # is already the one that we need.
    if debian::codename::eq('buster') {
        # We need iptables 1.8.3+ from buster-backports as indicated
        # in https://github.com/kubernetes/kubernetes/issues/82361
        # The list of packages installed is composed by:
        # iptables + `apt-cache depends iptables`
        apt::package_from_component { 'iptables':
            component => 'component/iptables185',
            packages  => [
                'iptables', 'libip4tc0', 'libip6tc0', 'libiptc0',
                'libxtables12', 'libmnl0', 'libnetfilter-conntrack3',
                'libnfnetlink0', 'libnftnl11', 'netbase'
            ],
        }

        # This is needed to allow ferm to run properly, since
        # from 1.8.3 the default backend is nftables.
        alternatives::select { 'iptables':
            path => '/usr/sbin/iptables-legacy',
        }

        alternatives::select { 'ip6tables':
            path => '/usr/sbin/ip6tables-legacy',
        }
    }
}
