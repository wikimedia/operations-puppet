# SPDX-License-Identifier: Apache-2.0
class profile::kubernetes::node (
    K8s::KubernetesVersion $version = lookup('profile::kubernetes::version'),
    Stdlib::Fqdn $master_fqdn = lookup('profile::kubernetes::master_fqdn'),
    Array[Stdlib::Host] $master_hosts = lookup('profile::kubernetes::master_hosts'),
    String $infra_pod = lookup('profile::kubernetes::infra_pod', { default_value => 'docker-registry.discovery.wmnet/pause:3.6-1' }),
    Boolean $use_cni = lookup('profile::kubernetes::use_cni'),
    Stdlib::Httpurl $prometheus_url   = lookup('profile::kubernetes::node::prometheus_url', { default_value => "http://prometheus.svc.${::site }.wmnet/k8s" }),
    String $kubelet_cluster_domain = lookup('profile::kubernetes::node::kubelet_cluster_domain', { default_value => 'cluster.local' }),
    Optional[Stdlib::IP::Address] $kubelet_cluster_dns = lookup('profile::kubernetes::node::kubelet_cluster_dns', { default_value => undef }),
    Optional[Array[String]] $kubelet_extra_params = lookup('profile::kubernetes::node::kubelet_extra_params', { default_value => undef }),
    Optional[Array[String]] $kubelet_node_labels = lookup('profile::kubernetes::node::kubelet_node_labels', { default_value => [] }),
    Optional[Array[K8s::Core::V1Taint]] $kubelet_node_taints = lookup('profile::kubernetes::node::kubelet_node_taints', { default_value => [] }),
    Boolean $ipv6dualstack = lookup('profile::kubernetes::ipv6dualstack', { default_value => false }),
    Optional[String] $docker_kubernetes_user_password = lookup('profile::kubernetes::node::docker_kubernetes_user_password', { default_value => undef }),
    K8s::ClusterCIDR $cluster_cidr = lookup('profile::kubernetes::cluster_cidr'),
    # It is expected that there is a second intermediate suffixed with _front_proxy to be used
    # to configure the aggregation layer. So by setting "wikikube" here you are required to add
    # the intermediates "wikikube" and "wikikube_front_proxy".
    #
    # FIXME: This should be something like "cluster group/name" while retaining the discrimination
    #        between production and staging as we don't want to share the same intermediate across
    #        that boundary.
    # FIXME: This is *not* optional for k8s versions > 1.16, make it mandatory after 1.23 migration
    Cfssl::Ca_name $pki_intermediate = lookup('profile::kubernetes::pki::intermediate'),
    # 952200 seconds is the default from cfssl::cert:
    # the default https checks go warning after 10 full days i.e. anywhere
    # from 864000 to 950399 seconds before the certificate expires.  As such set this to
    # 11 days + 30 minutes to capture the puppet run schedule.
    Integer[1800] $pki_renew_seconds = lookup('profile::kubernetes::pki::renew_seconds', { default_value => 952200 })
) {
    require profile::rsyslog::kubernetes
    # Using netbox to know where we are situated in the datacenter
    require profile::netbox::host

    # Enable performance governor for hardware nodes
    class { 'cpufrequtils': }

    rsyslog::input::file { 'kubernetes-json':
        path               => '/var/log/containers/*.log',
        reopen_on_truncate => 'on',
        addmetadata        => 'on',
        addceetag          => 'on',
        syslog_tag         => 'kubernetes',
        priority           => 8,
    }

    $kubelet_cert = profile::pki::get_cert($pki_intermediate, 'kubelet', {
        'profile'        => 'server',
        'renew_seconds'  => $pki_renew_seconds,
        'owner'          => 'kube',
        'outdir'         => '/etc/kubernetes/pki',
        'hosts'          => [
            $facts['hostname'],
            $facts['fqdn'],
            $facts['ipaddress'],
            $facts['ipaddress6'],
        ],
        'notify_service' => 'kubelet'
    })

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

    # Setup kubelet
    $kubelet_kubeconfig = '/etc/kubernetes/kubelet.conf'
    $default_auth = profile::pki::get_cert($pki_intermediate, "system:node:${facts['fqdn']}", {
        'renew_seconds'  => $pki_renew_seconds,
        'names'          => [{ 'organisation' => 'system:nodes' }],
        'owner'          => 'kube',
        'outdir'         => '/etc/kubernetes/pki',
        'notify_service' => 'kubelet'
    })
    k8s::kubeconfig { $kubelet_kubeconfig:
        master_host => $master_fqdn,
        username    => 'default-auth',
        auth_cert   => $default_auth,
        owner       => 'kube',
        group       => 'kube',
    }

    # Get typology info from netbox data
    $location = $profile::netbox::host::location
    $region = $location['site']
    $zone = $location ? {
        # Ganeti instances will have their ganeti cluster and group as zone, like "ganeti-eqiad-a"
        Netbox::Host::Location::Virtual   => "ganeti-${location['ganeti_cluster']}-${location['ganeti_group']}",
        # The zone of metal instances depends on the layout of the row they are in
        Netbox::Host::Location::BareMetal => if $location['rack'] =~ /^[A-D]\d$/ {
                # The old row setup follows a per row redundancy model, therefore we
                # expect zone to include the row without rack number, like "row-a".
                regsubst($location['row'], "${region}-", '')
            } else {
                # With the new row setup (rows E and F currently) we include the rack number
                # (like "row-e2") as we moved to a per rack redundancy model. We also need calico
                # to select hosts in specific racks to BGP pair with their ToR switch.
                # See: https://phabricator.wikimedia.org/T306649
                "row-${location['rack']}"
            },
    }

    $topology_labels = [
        "topology.kubernetes.io/region=${downcase($region)}",
        "topology.kubernetes.io/zone=${downcase($zone)}",
    ]

    $node_labels = concat($kubelet_node_labels, $topology_labels, "node.kubernetes.io/disk-type=${disk_type}")
    class { 'k8s::kubelet':
        cni                             => $use_cni,
        cluster_domain                  => $kubelet_cluster_domain,
        cluster_dns                     => $kubelet_cluster_dns,
        pod_infra_container_image       => $infra_pod,
        kubelet_cert                    => $kubelet_cert,
        kubeconfig                      => $kubelet_kubeconfig,
        node_labels                     => $node_labels,
        node_taints                     => $kubelet_node_taints,
        extra_params                    => $kubelet_extra_params,
        version                         => $version,
        ipv6dualstack                   => $ipv6dualstack,
        docker_kubernetes_user_password => $docker_kubernetes_user_password,
    }

    # Setup kube-proxy
    $kubeproxy_kubeconfig = '/etc/kubernetes/proxy.conf'
    $default_proxy = profile::pki::get_cert($pki_intermediate, 'system:kube-proxy', {
        'renew_seconds'  => $pki_renew_seconds,
        'names'          => [{ 'organisation' => 'system:node-proxier' }],
        'owner'          => 'kube',
        'outdir'         => '/etc/kubernetes/pki',
        'notify_service' => 'kube-proxy'
    })
    k8s::kubeconfig { $kubeproxy_kubeconfig:
        master_host => $master_fqdn,
        username    => 'default-proxy',
        auth_cert   => $default_proxy,
        owner       => 'kube',
        group       => 'kube',
    }
    class { 'k8s::proxy':
        kubeconfig    => $kubeproxy_kubeconfig,
        version       => $version,
        ipv6dualstack => $ipv6dualstack,
        cluster_cidr  => $cluster_cidr,
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

    $kubelet_default_port = 10250
    $master_hosts_ferm = join($master_hosts, ' ')
    ferm::service { 'kubelet-http':
        proto  => 'tcp',
        port   => $kubelet_default_port,
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

    # docker/runc will spam syslog for every exec inside a container, see:
    # https://github.com/docker/for-linux/issues/679
    # Stop the messages from reaching syslog until there is a proper fix available.
    rsyslog::conf { 'block-docker-mount-spam':
        priority => 1,
        content  => 'if $msg contains "run-docker-runtime\\\\x2drunc-moby-" and $msg contains ".mount: Succeeded." then { stop }',
    }

    # We've seen issues with tailing container logs as kubelet a lot of inotify instances.
    # Increase the inotify limits (from Debian default 8192, 128). The new values don't have a real meaning,
    # they've been copied from what we use on prometheus nodes.
    sysctl::parameters { 'increase_inotify_limits':
        values => {
            'fs.inotify.max_user_watches'   => 32768,
            'fs.inotify.max_user_instances' => 512,
        },
    }
}
