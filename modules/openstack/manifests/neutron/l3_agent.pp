class openstack::neutron::l3_agent(
    $version,
    $report_interval,
    String[1] $wan_nic,
    String[1] $virt_nic,
    Enum['linuxbridge', 'openvswitch'] $interface_driver,
    $enabled=true,
) {

    class { "openstack::neutron::l3_agent::${version}":
        report_interval  => $report_interval,
        interface_driver => $interface_driver,
    }

    service {'neutron-l3-agent':
        ensure  => $enabled,
        require => Package['neutron-l3-agent'],
    }

    # ensure the module is loaded at boot, otherwise sysctl parameters might be ignored
    kmod::module { 'nf_conntrack':
        ensure => present,
    }

    # if the NIC has the legacy naming 'eth0.xxxx' then we need to replace the dot with a slash
    $nic_virt = regsubst($virt_nic, '[.]', '/')
    $nic_wan  = regsubst($wan_nic, '[.]', '/')

    sysctl::parameters { 'openstack':
        values   => {
            # Turn off IP filter, only on dataplane
            "net.ipv4.conf.${nic_virt}.rp_filter"  => 0,
            "net.ipv4.conf.${nic_wan}.rp_filter"   => 0,
            # Enable IP forwarding, only on dataplane subinterfaces
            "net.ipv4.conf.${nic_virt}.forwarding" => 1,
            "net.ipv4.conf.${nic_wan}.forwarding"  => 1,
            "net.ipv6.conf.${nic_virt}.forwarding" => 1,
            "net.ipv6.conf.${nic_wan}.forwarding"  => 1,
            # Disable RA, only on dataplane
            "net.ipv6.conf.${nic_virt}.accept_ra"  => 0,
            "net.ipv6.conf.${nic_wan}.accept_ra"   => 0,

            # Tune arp cache table
            'net.ipv4.neigh.default.gc_thresh1'    => 1024,
            'net.ipv4.neigh.default.gc_thresh2'    => 2048,
            'net.ipv4.neigh.default.gc_thresh3'    => 4096,

            # Increase connection tracking size
            # and bucket since all of CloudVPS VM instances ingress/egress
            # are flowing through cloudnet servers
            # The values here are somewhat related to the ones in the hypervisors.
            # lets try to keep a 4x ratio between buckets and max
            'net.netfilter.nf_conntrack_buckets'   => 8388608,  # 2^22
            'net.netfilter.nf_conntrack_max'       => 33554432, # 4 * 2^22
        },
        priority => 50,
    }

    class { '::openstack::monitor::neutron::l3_agent_conntrack': }

    # our custom daemon to plug in additional config to neutron l3 agent
    $daemon = 'wmcs-netns-events'
    file { "/usr/local/sbin/${daemon}" :
        ensure => present,
        owner  => root,
        group  => root,
        mode   => '0755',
        source => "puppet:///modules/openstack/neutron/${daemon}.py",
        notify => Systemd::Service[$daemon],
    }
    $daemon_config = 'wmcs-netns-events-config.yaml'
    file { "/etc/${daemon_config}":
        ensure => present,
        owner  => root,
        group  => root,
        mode   => '0644',
        source => "puppet:///modules/openstack/neutron/${daemon_config}",
        notify => Systemd::Service[$daemon],
    }
    systemd::service { $daemon:
        restart  => true,
        content  => systemd_template($daemon),
        override => false,
    }
}
