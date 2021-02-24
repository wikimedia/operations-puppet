class profile::kubernetes::node(
    Stdlib::Fqdn $master_fqdn = lookup('profile::kubernetes::master_fqdn'),
    Array[Stdlib::Host] $master_hosts = lookup('profile::kubernetes::master_hosts'),
    String $infra_pod = lookup('profile::kubernetes::infra_pod'),
    Boolean $use_cni = lookup('profile::kubernetes::use_cni'),
    Boolean $masquerade_all = lookup('profile::kubernetes::node::masquerade_all', {default_value => true}),
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes', {default_value => []}),
    Stdlib::Unixpath $kubelet_config = lookup('profile::kubernetes::node::kubelet_config', {default_value => '/etc/kubernetes/kubelet_config'}),
    Stdlib::Unixpath $kubeproxy_config = lookup('profile::kubernetes::node::kubeproxy_config', {default_value => '/etc/kubernetes/kubeproxy_config'}),
    Stdlib::Httpurl $prometheus_url   = lookup('profile::kubernetes::node::prometheus_url', {default_value => "http://prometheus.svc.${::site}.wmnet/k8s"}),
    String $kubelet_cluster_domain = lookup('profile::kubernetes::node::kubelet_cluster_domain', {default_value => 'kube'}),
    Optional[Stdlib::IP::Address] $kubelet_cluster_dns = lookup('profile::kubernetes::node::kubelet_cluster_dns', {default_value => undef}),
    String $kubelet_username = lookup('profile::kubernetes::node::kubelet_username', {default_value => 'kubelet'}),
    String $kubelet_token = lookup('profile::kubernetes::node::kubelet_token'),
    Optional[Array[String]] $kubelet_extra_params = lookup('profile::kubernetes::node::kubelet_extra_params', {default_value => undef}),
    Optional[Array[String]] $kubelet_node_labels = lookup('profile::kubernetes::node::kubelet_node_labels', {default_value => []}),
    Optional[Array[String]] $kubelet_node_taints = lookup('profile::kubernetes::node::kubelet_node_taints', {default_value => []}),
    String $kubeproxy_username = lookup('profile::kubernetes::node::kubeproxy_username', {default_value => 'system:kube-proxy'}),
    String $kubeproxy_token = lookup('profile::kubernetes::node::kubeproxy_token'),
    Boolean $packages_from_future = lookup('profile::kubernetes::node::packages_from_future', {default_value => false}),
    Optional[String] $kubeproxy_metrics_bind_address = lookup('profile::kubernetes::node::kubeproxy_metrics_bind_address', {default_value => undef}),
    Boolean $kubelet_ipv6 = lookup('profile::kubernetes::node::kubelet_ipv6', {default_value => false}),
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

    base::expose_puppet_certs { '/etc/kubernetes':
        provide_private => true,
        user            => 'root',
        group           => 'root',
    }

    file { '/etc/kubernetes':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    k8s::kubeconfig { $kubelet_config:
        master_host => $master_fqdn,
        username    => $kubelet_username,
        token       => $kubelet_token,
    }
    class { '::k8s::kubelet':
        listen_address            => '0.0.0.0',
        cni                       => $use_cni,
        cluster_domain            => $kubelet_cluster_domain,
        cluster_dns               => $kubelet_cluster_dns,
        pod_infra_container_image => $infra_pod,
        tls_cert                  => '/etc/kubernetes/ssl/cert.pem',
        tls_key                   => '/etc/kubernetes/ssl/server.key',
        kubeconfig                => $kubelet_config,
        node_labels               => $kubelet_node_labels,
        node_taints               => $kubelet_node_taints,
        extra_params              => $kubelet_extra_params,
        packages_from_future      => $packages_from_future,
        kubelet_ipv6              => $kubelet_ipv6,
    }

    k8s::kubeconfig { $kubeproxy_config:
        master_host => $master_fqdn,
        username    => $kubeproxy_username,
        token       => $kubeproxy_token,
    }
    class { '::k8s::proxy':
        masquerade_all       => $masquerade_all,
        metrics_bind_address => $kubeproxy_metrics_bind_address,
        kubeconfig           => $kubeproxy_config,
        packages_from_future => $packages_from_future,
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

    if !empty($prometheus_nodes) {
        $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
        ferm::service { 'kubelet-http-readonly-prometheus':
            proto  => 'tcp',
            port   => '10255',
            srange => "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"
        }
        ferm::service { 'kube-proxy-http-readonly-prometheus':
            proto  => 'tcp',
            port   => '10249',
            srange => "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"
        }
    }
    # Alert us if kubelet operational latencies exceed a certain threshold. TODO: reevaluate
    # thresholds
    monitoring::check_prometheus { 'kubelet_operational_latencies':
        description     => 'kubelet operational latencies',
        query           => "instance_operation_type:kubelet_runtime_operations_latency_microseconds:avg5m{instance=\"${::fqdn}\"}",
        prometheus_url  => $prometheus_url,
        nan_ok          => true,
        warning         => 400000,
        critical        => 850000,
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/kubernetes-kubelets?orgId=1'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Kubernetes',
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
}
