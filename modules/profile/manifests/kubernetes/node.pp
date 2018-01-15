class profile::kubernetes::node(
  $master_fqdn = hiera('profile::kubernetes::master_fqdn'),
  $master_hosts = hiera('profile::kubernetes::master_hosts'),
  $infra_pod = hiera('profile::kubernetes::infra_pod'),
  $use_cni = hiera('profile::kubernetes::use_cni'),
  $masquerade_all = hiera('profile::kubernetes::node::masquerade_all', true),
  $username = hiera('profile::kubernetes::node::username', 'client-infrastructure'),
  $prometheus_nodes = hiera('prometheus_nodes', []),
  $kubelet_config = hiera('profile::kubernetes::node::kubelet_config', '/etc/kubernetes/kubeconfig'),
  $kubeproxy_config = hiera('profile::kubernetes::node::kubeproxy_config', '/etc/kubernetes/kubeconfig'),
  $prod_firewalls   = hiera('profile::kubernetes::node::prod_firewalls', true),
  $prometheus_url   = hiera('profile::kubernetes::node::prometheus_url', "http://prometheus.svc.${::site}.wmnet/k8s"),
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

    class { '::k8s::kubelet':
        master_host               => $master_fqdn,
        listen_address            => '0.0.0.0',
        cni                       => $use_cni,
        pod_infra_container_image => $infra_pod,
        tls_cert                  => '/etc/kubernetes/ssl/cert.pem',
        tls_key                   => '/etc/kubernetes/ssl/server.key',
        kubeconfig                => $kubelet_config,
    }
    class { '::k8s::proxy':
        master_host    => $master_fqdn,
        masquerade_all => $masquerade_all,
        kubeconfig     => $kubeproxy_config,
    }

    # Set the host as a router for IPv6 in order to allow pods to have an IPv6
    # address
    # If the host considers itself as a router (IP forwarding enabled), it will
    # ignore all router advertisements, breaking IPv6 SLAAC. Accept Router
    # Advertisements even if forwarding is enabled, but only on the primary
    # interface
    # lint:ignore:arrow_alignment
    sysctl::parameters { 'ipv6-accept-ra':
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
        query           => "scalar(\
            sum(rate(kubelet_runtime_operations_latency_microseconds_sum{\
            job=\"k8s-node\", instance=\"${::fqdn}\"}[5m]))/ \
            sum(rate(kubelet_runtime_operations_latency_microseconds_count{\
            job=\"k8s-node\", instance=\"${::fqdn}\"}[5m])))",
        prometheus_url  => $prometheus_url,
        warning         => 10000,
        critical        => 15000,
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/kubernetes-kubelets?orgId=1']
    }
}
