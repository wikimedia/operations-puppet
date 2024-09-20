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

    # FIXME: Ensure kube user/group as well as /etc/kubernetes/pki is created with proper permissions
    # before the first pki::get_cert call: https://phabricator.wikimedia.org/T337826
    unless defined(Group['kube']) {
        group { 'kube':
            ensure => present,
            system => true,
        }
    }
    unless defined(User['kube']) {
        user { 'kube':
            ensure => present,
            gid    => 'kube',
            system => true,
            home   => '/nonexistent',
            shell  => '/usr/sbin/nologin',
        }
    }
    $cert_dir = '/etc/kubernetes/pki'
    unless defined(File[$cert_dir]) {
        file { $cert_dir:
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }
    # Blacklist the wdat_wdt watchdog kernel module present in some R440s
    # Due to some race condition that is triggered by a slow to stop container
    # the machines using this watchdog driver don't finish a proper reboot but
    # are rather rebooted by the watchdog. The watchdog triggered reboot causes
    # the firmware to ask for a manual action on the next boot (Press F1), which
    # is just unacceptable. Blacklist the module as a workaround. T354413
    if $::productname == 'PowerEdge R440' {
        kmod::blacklist { 'r440_wdat_wdt':
            modules => [ 'wdat_wdt' ],
            rmmod   => true,
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

    # additional rsyslog imfile remedy, unconditionally restart rsyslog
    # every few hours
    class { 'toil::rsyslog_imfile_remedy': }

    # rsyslog imfile fd leak seems fixed with 8.2404.0-1~bpo11+1
    # absent the bandaid to completely remove it later.
    # https://phabricator.wikimedia.org/T357616
    $release_deleted_inotify_watches = 'rsyslog-release-deleted-inotify-watches'
    $command = "/usr/local/sbin/${release_deleted_inotify_watches}"
    file { $command:
        ensure => 'absent',
        mode   => '0544',
        owner  => 'root',
        group  => 'root',
    }
    $minute = fqdn_rand(59, $release_deleted_inotify_watches)
    systemd::timer::job { $release_deleted_inotify_watches:
        ensure      => 'absent',
        description => 'Restart rsyslog to release inotify watches of deleted container logs',
        user        => 'root',
        command     => $command,
        interval    => { 'start' => 'OnCalendar', 'interval' => "*-*-* *:${minute}:00" },
    }

    $kubelet_cert = profile::pki::get_cert($k8s_config['pki_intermediate_base'], 'kubelet', {
        'profile'         => 'server',
        'renew_seconds'   => $k8s_config['pki_renew_seconds'],
        'owner'           => 'kube',
        'outdir'          => $cert_dir,
        'hosts'           => [
            $facts['hostname'],
            $facts['fqdn'],
            $facts['ipaddress'],
            $facts['ipaddress6'],
        ],
        'notify_services' => ['kubelet'],
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
        'renew_seconds'   => $k8s_config['pki_renew_seconds'],
        'names'           => [{ 'organisation' => 'system:nodes' }],
        'owner'           => 'kube',
        'outdir'          => $cert_dir,
        'notify_services' => ['kubelet'],
    })
    k8s::kubeconfig { $kubelet_kubeconfig:
        master_host => $k8s_config['master'],
        username    => 'default-auth',
        auth_cert   => $default_auth,
        owner       => 'kube',
        group       => 'kube',
    }

    # Get typology info from Netbox and LLDP data
    $location = $profile::netbox::host::location
    $region = $location['site']
    $zone = $location ? {
        # Ganeti instances will have their ganeti cluster and group as zone, like "ganeti-eqiad-a"
        Netbox::Device::Location::Virtual   => "ganeti-${location['ganeti_cluster']}-${location['ganeti_group']}",
        # The zone of metal instances depends on the layout of the row they are in
        Netbox::Device::Location::BareMetal =>
            if !$facts['lldp']['parent'] {
                fail('LLDP fact finding failed, \
                failing the entire Puppet run to avoid unwanted kubelet topology changes.')
            } elsif $facts['lldp']['parent'] =~ /^lsw/ {
                # Old-> new switches transition - to be removed once the transition is over
                # Case where the server has been physically moved to the new switches,
                # But is still in the old row wise codfw vlans
                if $facts['lldp'][$facts['interface_primary']]['vlans']['untagged_vlan'] in [2017, 2018, 2019, 2020] {
                    regsubst($location['row'], "${region}-", '')
                } else {
                    # L3 ToR switches in the core sites are named "lsw", while row wide VCs are "asw"
                    # in that case, their "availlability zone" is limited to the rack
                    "row-${location['rack']}"
                }
            } else {
                # The old row setup follows a per row redundancy model, therefore we
                # expect zone to include the row without rack number, like "row-a".
                regsubst($location['row'], "${region}-", '')
            },
    }

    $topology_labels = [
        "topology.kubernetes.io/region=${downcase($region)}",
        "topology.kubernetes.io/zone=${downcase($zone)}",
    ]

    $node_labels = concat($kubelet_node_labels, $topology_labels, "node.kubernetes.io/disk-type=${disk_type}")

    if $facts['fqdn'] in $k8s_config['control_plane_nodes'] {
        $system_reserved = undef
    } else {
        # If this node is not a master, compute reserved system resources
        # Reserve memory:
        # * 25% of the first 4 GiB == 1 GiB
        # * 20% of the next 4 GiB == 0.8 GiB
        # * 10% of the next 8 GiB == 0.8 GiB
        # *  6% of the next 112 GiB == 6.72 GiB
        # *  3% of anything above 128 GiB
        $one_gib_bytes = 1074176000
        $system_mem_bytes = $facts['memory']['system']['total_bytes']
        if $system_mem_bytes <= $one_gib_bytes * 4 {
            $reserved_mem_bytes = 25 * $system_mem_bytes / 100
        } elsif $system_mem_bytes <= $one_gib_bytes * 8 {
            $reserved_mem_bytes = $one_gib_bytes + 20 * ($system_mem_bytes - $one_gib_bytes * 4) / 100
        } elsif $system_mem_bytes <= $one_gib_bytes * 16 {
            $reserved_mem_bytes = 1.8 * $one_gib_bytes + 10 * ($system_mem_bytes - $one_gib_bytes * 8) / 100
        } elsif $system_mem_bytes <= $one_gib_bytes * 128 {
            $reserved_mem_bytes = 2.6 * $one_gib_bytes + 6 * ($system_mem_bytes - $one_gib_bytes * 16) / 100
        } else {
            $reserved_mem_bytes = 9.32 * $one_gib_bytes + 3 * ($system_mem_bytes - $one_gib_bytes * 128) / 100
        }

        # Reserve CPU
        # 6% of the first core
        # 1% of the second core
        # 0.5% of the next 2 cores (up to 4)
        # 0.01% of all cores above 4
        $system_cpus = $facts['processorcount']
        if $system_cpus == 1 {
            $reserved_cpus = 0.06
        } elsif $system_cpus == 2 {
            $reserved_cpus = 0.07
        } elsif $system_cpus <= 4 {
            $reserved_cpus = (0.07 + 0.5 * ($system_cpus - 2) / 100) * $system_cpus
        } else {
            $reserved_cpus = (0.08 + 0.01 * ($system_cpus - 4) / 100) * $system_cpus
        }

        $system_reserved = {
            'cpu' => sprintf('%.1f', $reserved_cpus),
            'memory' => sprintf('%.2fGi', $reserved_mem_bytes / 1024.0 / 1024.0 / 1024.0),
        }
    }

    # Check if containerd should be used as CRI
    if defined(Class['profile::containerd']) {
        $containerd_cri = $profile::containerd::ensure ? {
            'absent'  => false,
            default   => true,
        }
    } else {
        $containerd_cri = false
    }
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
        system_reserved                 => $system_reserved,
        containerd_cri                  => $containerd_cri,
    }

    # Setup kube-proxy
    $kubeproxy_kubeconfig = '/etc/kubernetes/proxy.conf'
    $default_proxy = profile::pki::get_cert($k8s_config['pki_intermediate_base'], 'system:kube-proxy', {
        'renew_seconds'   => $k8s_config['pki_renew_seconds'],
        'names'           => [{ 'organisation' => 'system:node-proxier' }],
        'owner'           => 'kube',
        'outdir'          => $cert_dir,
        'notify_services' => ['kube-proxy'],
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

    # Override for ferm.service to autorestart in case of kube-proxy race-condition
    # T354855
    systemd::override { 'ferm-service-auto-restart':
        unit   => 'ferm',
        source => 'puppet:///modules/profile/kubernetes/node/ferm_systemd_override',
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

    rsyslog::conf { 'kubernetes-node-filters':
      priority => 10,
      source   => 'puppet:///modules/profile/kubernetes/node/kubernetes-node-filters.rsyslog.conf',
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

    # Populating apparmor profile for fun and profit
    class { 'apparmor': }
    $apparmor_profiles = 'apparmor_profiles' in $k8s_config ? {
        true  => $k8s_config['apparmor_profiles'],
        false => [],
    }
    $apparmor_profiles.each |$pname| {
        apparmor::profile { "containers.${pname}":
            source => "puppet:///modules/profile/kubernetes/node/${pname}",
        }
    }
}
