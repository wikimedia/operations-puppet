class profile::kubernetes::node(
  $master_fqdn = hiera('profile::kubernetes::master_fqdn'),
  $master_hosts = hiera('profile::kubernetes::master_hosts'),
  $infra_pod = hiera('profile::kubernetes::infra_pod'),
  $use_cni = hiera('profile::kubernetes::use_cni'),
  $masquerade_all = hiera('profile::kubernetes::node::masquerade_all', true),
  # $username is deprecated, was a flawed approach
  $username = hiera('profile::kubernetes::node::username', 'client-infrastructure'),
  $prometheus_nodes = hiera('prometheus_nodes', []),
  $kubelet_config = hiera('profile::kubernetes::node::kubelet_config', '/etc/kubernetes/kubeconfig'),
  $kubeproxy_config = hiera('profile::kubernetes::node::kubeproxy_config', '/etc/kubernetes/kubeconfig'),
  $prod_firewalls   = hiera('profile::kubernetes::node::prod_firewalls', true),
  $prometheus_url   = hiera('profile::kubernetes::node::prometheus_url', "http://prometheus.svc.${::site}.wmnet/k8s"),
  $kubelet_username = hiera('profile::kubernetes::node::kubelet_username', undef),
  $kubelet_token = hiera('profile::kubernetes::node::kubelet_token', undef),
  $kubelet_extra_params = hiera('profile::kubernetes::node::kubelet_extra_params', undef),
  $kubelet_node_labels = hiera('profile::kubernetes::node::kubelet_node_labels', []),
  $kubelet_node_taints = hiera('profile::kubernetes::node::kubelet_node_taints', []),
  $kubeproxy_username = hiera('profile::kubernetes::node::kubeproxy_username', undef),
  $kubeproxy_token = hiera('profile::kubernetes::node::kubeproxy_token', undef),
  ) {

    base::expose_puppet_certs { '/etc/kubernetes':
        provide_private => true,
        user            => 'root',
        group           => 'root',
    }

    class { '::k8s::infrastructure_config':
        master_host => $master_fqdn,
        username    => $username,
    }

    # Funnily enough, this is not $kubelet_config cause we still need to support
    # labs which doesn't use/support this. TODO Fix this
    if ($kubelet_username and $kubelet_token) {
        k8s::kubeconfig { '/etc/kubernetes/kubelet_config':
            master_host => $master_fqdn,
            username    => $kubelet_username,
            token       => $kubelet_token,
        }
    }

    class { '::k8s::kubelet':
        listen_address            => '0.0.0.0',
        cni                       => $use_cni,
        pod_infra_container_image => $infra_pod,
        tls_cert                  => '/etc/kubernetes/ssl/cert.pem',
        tls_key                   => '/etc/kubernetes/ssl/server.key',
        kubeconfig                => $kubelet_config,
        node_labels               => $kubelet_node_labels,
        node_taints               => $kubelet_node_taints,
        extra_params              => $kubelet_extra_params,
        require                   => Class['::k8s::infrastructure_config'],
    }

    # Funnily enough, this is not $kubeproxy_config cause we still need to support
    # labs which doesn't use/support this. TODO Fix this
    if ($kubeproxy_username and $kubeproxy_token) {
        k8s::kubeconfig { '/etc/kubernetes/kubeproxy_config':
            master_host => $master_fqdn,
            username    => $kubeproxy_username,
            token       => $kubeproxy_token,
        }
    }

    class { '::k8s::proxy':
        master_host    => $master_fqdn,
        masquerade_all => $masquerade_all,
        kubeconfig     => $kubeproxy_config,
        require        => Class['::k8s::infrastructure_config'],
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

    # We can't use this for VMs because of the AAAA lookups
    if $prod_firewalls {
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
}
