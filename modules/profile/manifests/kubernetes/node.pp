# SPDX-License-Identifier: Apache-2.0
class profile::kubernetes::node (
    String $kubernetes_cluster_name                          = lookup('profile::kubernetes::cluster_name'),
    Optional[Array[String]] $kubelet_node_labels             = lookup('profile::kubernetes::node::kubelet_node_labels', { default_value => [] }),
    Optional[Array[String]] $kubelet_extra_params            = lookup('profile::kubernetes::node::kubelet_extra_params', { default_value => undef }),
    Optional[Array[K8s::Core::V1Taint]] $kubelet_node_taints = lookup('profile::kubernetes::node::kubelet_node_taints', { default_value => [] }),
    Optional[String] $docker_kubernetes_user_password        = lookup('profile::kubernetes::node::docker_kubernetes_user_password', { default_value => undef }),
) {
    require profile::rsyslog::kubernetes
    # Using netbox to know where we are situated in the datacenter
    require profile::netbox::host
    # Ensure /etc/kubernetes/pki is created with proper permissions before the first pki::get_cert call
    # FIXME: https://phabricator.wikimedia.org/T337826
    $cert_dir = '/etc/kubernetes/pki'
    unless defined(File[$cert_dir]) {
        file { $cert_dir:
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    $k8s_config = k8s::fetch_cluster_config($kubernetes_cluster_name)

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

    $kubelet_cert = profile::pki::get_cert($k8s_config['pki_intermediate_base'], 'kubelet', {
        'profile'        => 'server',
        'renew_seconds'  => $k8s_config['pki_renew_seconds'],
        'owner'          => 'kube',
        'outdir'         => $cert_dir,
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
    $default_auth = profile::pki::get_cert($k8s_config['pki_intermediate_base'], "system:node:${facts['fqdn']}", {
        'renew_seconds'  => $k8s_config['pki_renew_seconds'],
        'names'          => [{ 'organisation' => 'system:nodes' }],
        'owner'          => 'kube',
        'outdir'         => $cert_dir,
        'notify_service' => 'kubelet'
    })
    k8s::kubeconfig { $kubelet_kubeconfig:
        master_host => $k8s_config['master'],
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
        Netbox::Device::Location::Virtual   => "ganeti-${location['ganeti_cluster']}-${location['ganeti_group']}",
        # The zone of metal instances depends on the layout of the row they are in
        Netbox::Device::Location::BareMetal => if $location['rack'] =~ /^[A-D]\d$/ {
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
        cni                             => $k8s_config['use_cni'],
        cluster_dns                     => $k8s_config['cluster_dns'],
        pod_infra_container_image       => $k8s_config['infra_pod'],
        kubelet_cert                    => $kubelet_cert,
        kubeconfig                      => $kubelet_kubeconfig,
        node_labels                     => $node_labels,
        node_taints                     => $kubelet_node_taints,
        extra_params                    => $kubelet_extra_params,
        version                         => $k8s_config['version'],
        ipv6dualstack                   => $k8s_config['ipv6dualstack'],
        docker_kubernetes_user_password => $docker_kubernetes_user_password,
    }

    # Setup kube-proxy
    $kubeproxy_kubeconfig = '/etc/kubernetes/proxy.conf'
    $default_proxy = profile::pki::get_cert($k8s_config['pki_intermediate_base'], 'system:kube-proxy', {
        'renew_seconds'  => $k8s_config['pki_renew_seconds'],
        'names'          => [{ 'organisation' => 'system:node-proxier' }],
        'owner'          => 'kube',
        'outdir'         => $cert_dir,
        'notify_service' => 'kube-proxy'
    })
    k8s::kubeconfig { $kubeproxy_kubeconfig:
        master_host => $k8s_config['master'],
        username    => 'default-proxy',
        auth_cert   => $default_proxy,
        owner       => 'kube',
        group       => 'kube',
    }
    class { 'k8s::proxy':
        kubeconfig    => $kubeproxy_kubeconfig,
        version       => $k8s_config['version'],
        ipv6dualstack => $k8s_config['ipv6dualstack'],
        cluster_cidr  => $k8s_config['cluster_cidr'],
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
    $control_plane_nodes_ferm = join($k8s_config['control_plane_nodes'], ' ')
    ferm::service { 'kubelet-http':
        proto  => 'tcp',
        port   => $kubelet_default_port,
        srange => "(@resolve((${control_plane_nodes_ferm})) @resolve((${control_plane_nodes_ferm}), AAAA))",
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
