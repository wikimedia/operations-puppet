class profile::wmcs::cloudgw (
    Array[Stdlib::IP::Address::V4::CIDR]           $virt_subnets              = lookup('profile::wmcs::cloudgw::virt_subnets_cidr',        {default_value => ['172.16.128.0/24']}),
    Optional[Array[Stdlib::IP::Address::V6::CIDR]] $virt_subnets_v6           = lookup('profile::wmcs::cloudgw::virt_subnets_cidr_v6',     {default_value => undef}),
    Integer                                        $virt_vlan                 = lookup('profile::wmcs::cloudgw::virt_vlan',                {default_value => 2107}),
    Stdlib::IP::Address                            $virt_peer                 = lookup('profile::wmcs::cloudgw::virt_peer',                {default_value => '127.0.0.5'}),
    Stdlib::IP::Address                            $virt_addr                 = lookup('profile::wmcs::cloudgw::virt_addr',                {default_value => '127.0.0.4'}),
    Integer[1,32]                                  $virt_netm                 = lookup('profile::wmcs::cloudgw::virt_netm',                {default_value => 8}),
    Optional[Stdlib::IP::Address::V6]              $virt_peer_v6              = lookup('profile::wmcs::cloudgw::virt_peer_v6',             {default_value => undef}),
    Optional[Stdlib::IP::Address::V6]              $virt_addr_v6              = lookup('profile::wmcs::cloudgw::virt_addr_v6',             {default_value => undef}),
    Optional[Integer[1,128]]                       $virt_netm_v6              = lookup('profile::wmcs::cloudgw::virt_netm_v6',             {default_value => undef}),
    Array[Stdlib::IP::Address::V4::CIDR]           $virt_floating             = lookup('profile::wmcs::cloudgw::virt_floating',            {default_value => ['127.0.0.5/24']}),
    Integer                                        $wan_vlan                  = lookup('profile::wmcs::cloudgw::wan_vlan',                 {default_value => 2120}),
    Stdlib::IP::Address                            $wan_addr                  = lookup('profile::wmcs::cloudgw::wan_addr',                 {default_value => '127.0.0.4'}),
    Integer                                        $wan_netm                  = lookup('profile::wmcs::cloudgw::wan_netm',                 {default_value => 8}),
    Stdlib::IP::Address                            $wan_gw                    = lookup('profile::wmcs::cloudgw::wan_gw',                   {default_value => '127.0.0.1'}),
    Optional[Stdlib::IP::Address::V6]              $wan_addr_v6               = lookup('profile::wmcs::cloudgw::wan_addr_v6',              {default_value => undef}),
    Optional[Integer[1,128]]                       $wan_netm_v6               = lookup('profile::wmcs::cloudgw::wan_netm_v6',              {default_value => undef}),
    Optional[Stdlib::IP::Address::V6]              $wan_gw_v6                 = lookup('profile::wmcs::cloudgw::wan_gw_v6',                {default_value => undef}),
    Array[String]                                  $vrrp_vips                 = lookup('profile::wmcs::cloudgw::vrrp_vips',                {default_value => ['127.0.0.1 dev eno2']}),
    Stdlib::IP::Address                            $vrrp_peer                 = lookup('profile::wmcs::cloudgw::vrrp_peer',                {default_value => '127.0.0.1'}),
    Optional[Array[String]]                        $vrrp_vips_v6              = lookup('profile::wmcs::cloudgw::vrrp_vips_v6',             {default_value => undef}),
    Hash                                           $conntrackd                = lookup('profile::wmcs::cloudgw::conntrackd',               {default_value => {}}),
    Stdlib::IP::Address                            $routing_source            = lookup('profile::wmcs::cloudgw::routing_source_ip',        {default_value => '127.0.0.7'}),
    Optional[Array[Stdlib::IP::Address::V4]]       $cloud_filter              = lookup('profile::wmcs::cloudgw::cloud_filter',             {default_value => []}),
    Array[Stdlib::IP::Address::V4]                 $dmz_cidr                  = lookup('profile::wmcs::cloudgw::dmz_cidr',                 {default_value => []}),
    Array[Stdlib::IP::Address::V4::Cidr]           $public_cidrs              = lookup('profile::wmcs::cloud_private_subnet::public_cidrs',{default_value => []}),
    Stdlib::IP::Address::V4::Cidr                  $cloud_private_supernet    = lookup('profile::wmcs::cloud_private_subnet::supernet'),
) {
    ensure_packages('vlan')
    $nic_virt = "vlan${virt_vlan}"
    $nic_wan  = "vlan${wan_vlan}"

    nftables::file { 'cloudgw':
        ensure  => present,
        order   => 110,
        content => template('profile/wmcs/cloudgw/cloudgw.nft.erb'),
    }

    $rt_table_name = 'cloudgw'
    interface::routing_table { $rt_table_name:
        number => 10,
    }

    $vrf_interface = 'vrf-cloudgw'

    interface::tagged { "cloudgw_${nic_virt}":
        base_interface     => $facts['interface_primary'],
        vlan_id            => $virt_vlan,
        address            => $virt_addr,
        netmask            => $virt_netm,
        legacy_vlan_naming => false,
    }

    if $virt_addr_v6 != undef {
        interface::ip { "cloudgw_v6_${nic_virt}":
            interface => $nic_virt,
            address   => $virt_addr_v6,
            prefixlen => $virt_netm_v6,
        }
    }

    interface::tagged { "cloudgw_${nic_wan}":
        base_interface     => $facts['interface_primary'],
        vlan_id            => $wan_vlan,
        address            => $wan_addr,
        netmask            => $wan_netm,
        legacy_vlan_naming => false,
    }

    if $wan_addr_v6 != undef {
        interface::ip { "cloudgw_v6_${nic_wan}":
            interface => $nic_wan,
            address   => $wan_addr_v6,
            prefixlen => $wan_netm_v6,
        }

        # NOTE: it seems the kernel flushes routes when changing this
        # so make sure in the resulting system config, this sysctl is applied
        # before injecting the routes (below)
        # also, 'all' forwarding seems to enable $whatever that makes the IPv6
        # forwarding work for real on the VRF
        # however, explicitly disable on the primary interface, because it conflicts
        # with the accept_ra and token settings that we have per the d-i
        sysctl::parameters {'cloudgw-ipv6-forwarding':
            values   => {
                'net.ipv6.conf.all.forwarding'                           => 1,
                "net.ipv6.conf.${facts['interface_primary']}.forwarding" => 0,
            },
        }
    }

    [$nic_virt, $nic_wan].each |$nic| {
        interface::post_up_command { "cloudgw_${nic}_vrf":
            interface => $nic,
            command   => "ip link set ${nic} master ${vrf_interface}",
        }
        interface::post_up_command { "cloudgw_${nic}_ipv4_forwarding":
            interface => $nic,
            command   => "sysctl -w net.ipv4.conf.${nic}.forwarding=1",
        }
        interface::post_up_command { "cloudgw_${nic}_rp_filter":
            interface => $nic,
            command   => "sysctl -w net.ipv4.conf.${nic}.rp_filter=0",
        }
        interface::post_up_command { "cloudgw_${nic}_accept_ra":
            interface => $nic,
            command   => "sysctl -w net.ipv6.conf.${nic}.accept_ra=0",
        }
    }

    # NOTE: not using interface::route because it doesn't support custom table. We can do the refactor later.
    interface::post_up_command { 'default_vrf_route' :
        interface => $nic_wan,
        command   => "ip route add table ${rt_table_name} default via ${wan_gw} dev ${nic_wan}",
    }

    if $wan_gw_v6 != undef {
        interface::post_up_command { 'default_vrf_route_v6' :
            interface => $nic_wan,
            command   => "ip -6 route add table ${rt_table_name} default via ${wan_gw_v6} dev ${nic_wan}",
        }
    }

    # route internal VM networks to neutron
    $virt_subnets.each |$net| {
        interface::post_up_command { "route_${nic_virt}_virt_subnet_${net}" :
            interface => $nic_virt,
            command   => "ip route add ${net} table ${rt_table_name} nexthop via ${virt_peer} dev ${nic_virt}",
        }
    }
    # route floating IPs to neutron
    $virt_floating.each |$net| {
        interface::post_up_command { "route_${nic_virt}_floating_ips_${net}":
            interface => $nic_virt,
            command   => "ip route add ${net} table ${rt_table_name} nexthop via ${virt_peer} dev ${nic_virt}",
        }
    }

    # route virtual IPv6 networks to neutron
    if $virt_subnets_v6 != undef {
        $virt_subnets_v6.each |$net| {
            interface::post_up_command { "route_${nic_virt}_virt_subnet_${net}" :
                interface => $nic_virt,
                command   => "ip -6 route add ${net} table ${rt_table_name} nexthop via ${virt_peer_v6} dev ${nic_virt}",
            }
        }
    }

    file { '/etc/network/interfaces.d/cloudgw':
        ensure  => present,
        content => file('profile/wmcs/cloudgw/cloudgw'),
    }

    # ensure the module is loaded at boot, otherwise sysctl parameters might be ignored
    kmod::module { 'nf_conntrack':
        ensure => present,
    }

    sysctl::parameters { 'cloudgw':
        # NOTE: additional sysctl params are present in ifupdown template, see
        # modules/profile/templates/openstack/base/cloudgw/interfaces.erb for details.
        # It can't live here because race condition between systemd-udev and systemd-sysctl
        # See T305494 for details.
        values   => {
            # Enable TCP be liberal option. This increases chances of a NAT
            # flow surviving a failover scenario
            'net.netfilter.nf_conntrack_tcp_be_liberal' => 1,

            # Increase connection tracking size
            # and bucket since all of CloudVPS VM instances ingress/egress
            # are flowing through cloudgw servers.
            # The values here are somewhat related to the ones in the hypervisors.
            # lets try to keep a 4x ratio between buckets and max
            'net.netfilter.nf_conntrack_buckets'        => 8388608,  # 2^22
            'net.netfilter.nf_conntrack_max'            => 33554432, # 4 * 2^22
        },
        priority => 50,
    }

    class { 'keepalived':
        peers     => ['example.com'], # overriden by config template
        auth_pass => 'ignored',       # overriden by config template
        vips      => ['127.0.0.1'],   # overriden by config template
        config    => template('profile/wmcs/cloudgw/keepalived.conf.erb'),
    }

    nftables::file { 'keepalived_vrrp':
        order   => 105,
        content => "add rule inet base input ip saddr ${vrrp_peer} ip protocol vrrp accept\n",
    }

    # this expects a data structure like this:
    # profile::openstack::base::cloudgw::conntrackd_conf:
    #   node1:
    #     local_addr: node1.dc.wmnet
    #     remote_addr: node2.dc.wmnet
    #     filter_ipv4:
    #      - x.x.x.x
    #      - y.y.y.y
    #   node2:
    #     local_addr: node2.dc.wmnet
    #     remote_addr: node1.dc.wmnet
    #     filter_ipv4:
    #      - x.x.x.x
    #      - y.y.y.y

    $conntrackd_nic            = $facts['interface_primary']
    $conntrackd_local_address  = ipresolve($conntrackd[$::hostname]['local_addr'], 4)
    $conntrackd_remote_address = ipresolve($conntrackd[$::hostname]['remote_addr'], 4)
    $conntrackd_filter_ipv4    = $conntrackd[$::hostname]['filter_ipv4']

    class { 'conntrackd':
        conntrackd_cfg => template('profile/wmcs/cloudgw/conntrackd.conf.erb'),
        systemd_cfg    => file('profile/wmcs/cloudgw/conntrackd.service'),
    }

    nftables::file { 'conntrackd_tcp_3780':
        order   => 110,
        content => "add rule inet base input ip saddr ${conntrackd_remote_address} tcp dport 3780 ct state new accept\n",
    }
}
