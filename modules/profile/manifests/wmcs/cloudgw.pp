# @summary Manages the Cloud VPS edge firewall boxes
# @param virt_subnets OpenStack public tenant IPv4 subnets
# @param virt_subnets_v6 OpenStack public tenant IPv6 subnets
# @param virt_internal_subnets OpenStack tenant IPv4 subnets with no public connectivity
# @param virt_vlan cloud-gw-transport network VLAN tag
# @param virt_peer OpenStack network gateway IPv4 VIP in the cloud-gw-transport network
# @param virt_addr cloudgw IPv4 VIP in the cloud-gw-transport network
# @param virt_netm cloud-gw-transport network IPv4 network size
# @param virt_peer_v6 OpenStack network gateway IPv6 VIP in the cloud-gw-transport network
# @param virt_addr_v6 cloudgw IPv6 VIP in the cloud-gw-transport network
# @param virt_netm_v6 cloud-gw-transport network IPv6 network size
# @param virt_floating List of networks used for OpenStack floating IPv4 VIPs
# @param wan_vlan cloud-instance-transport VLAN tag
# @param wan_addr cloudgw IPv4 VIP in the cloud-gw-transport network
# @param wan_netm cloud-gw-transport network IPv4 network size
# @param wan_gw cloudsw IPv4 VIP in the cloud-gw-transport network
# @param wan_addr_v6 cloudgw IPv6 VIP in the cloud-gw-transport network
# @param wan_netm_v6 cloud-gw-transport network IPv6 network size
# @param wan_gw_v6 cloudsw IPv6 VIP in the cloud-gw-transport network
# @param vrrp_vips List of Keepalived-managed IPv4 VIPs in Keepalived's own config format
# @param vrrp_peer cloud-instance-transport IPv4 address of the other cloudgw host
# @param vrrp_vips_v6 List of Keepalived-managed IPv6 VIPs in Keepalived's own config format
# @param conntrackd Conntrackd settings
# @param routing_source Public IP address used for outbound NATed connections
# @param cloud_filter List of networks for whom traffic is dropped
# @param dmz_cidr List of networks exempt from egress NATting
# @param cloud_private_supernet Supernet for the cloud-private networks
class profile::wmcs::cloudgw (
    Array[Stdlib::IP::Address::V4::CIDR] $virt_subnets              = lookup('profile::wmcs::cloudgw::virt_subnets_cidr'),
    Array[Stdlib::IP::Address::V6::CIDR] $virt_subnets_v6           = lookup('profile::wmcs::cloudgw::virt_subnets_cidr_v6'),
    Array[Stdlib::IP::Address::V4::CIDR] $virt_internal_subnets     = lookup('profile::wmcs::cloudgw::virt_internal_subnets_cidr', {default_value => []}),
    Network::VLANTag                     $virt_vlan                 = lookup('profile::wmcs::cloudgw::virt_vlan'),
    Stdlib::IP::Address::V4::Nosubnet    $virt_peer                 = lookup('profile::wmcs::cloudgw::virt_peer'),
    Stdlib::IP::Address::V4::Nosubnet    $virt_addr                 = lookup('profile::wmcs::cloudgw::virt_addr'),
    Integer[1,32]                        $virt_netm                 = lookup('profile::wmcs::cloudgw::virt_netm'),
    Stdlib::IP::Address::V6::Nosubnet    $virt_peer_v6              = lookup('profile::wmcs::cloudgw::virt_peer_v6'),
    Stdlib::IP::Address::V6::Nosubnet    $virt_addr_v6              = lookup('profile::wmcs::cloudgw::virt_addr_v6'),
    Integer[1,128]                       $virt_netm_v6              = lookup('profile::wmcs::cloudgw::virt_netm_v6', {default_value => 64}),
    Array[Stdlib::IP::Address::V4::CIDR] $virt_floating             = lookup('profile::wmcs::cloudgw::virt_floating'),
    Network::VLANTag                     $wan_vlan                  = lookup('profile::wmcs::cloudgw::wan_vlan'),
    Stdlib::IP::Address::V4::Nosubnet    $wan_addr                  = lookup('profile::wmcs::cloudgw::wan_addr'),
    Integer[1,32]                        $wan_netm                  = lookup('profile::wmcs::cloudgw::wan_netm'),
    Stdlib::IP::Address::V4::Nosubnet    $wan_gw                    = lookup('profile::wmcs::cloudgw::wan_gw'),
    Stdlib::IP::Address::V6::Nosubnet    $wan_addr_v6               = lookup('profile::wmcs::cloudgw::wan_addr_v6'),
    Optional[Integer[1,128]]             $wan_netm_v6               = lookup('profile::wmcs::cloudgw::wan_netm_v6', {default_value => 64}),
    Optional[Stdlib::IP::Address::V6]    $wan_gw_v6                 = lookup('profile::wmcs::cloudgw::wan_gw_v6'),
    Array[String]                        $vrrp_vips                 = lookup('profile::wmcs::cloudgw::vrrp_vips'),
    Stdlib::IP::Address::V4::Nosubnet    $vrrp_peer                 = lookup('profile::wmcs::cloudgw::vrrp_peer'),
    Array[String]                        $vrrp_vips_v6              = lookup('profile::wmcs::cloudgw::vrrp_vips_v6'),
    Hash                                 $conntrackd                = lookup('profile::wmcs::cloudgw::conntrackd'),
    Stdlib::IP::Address::V4::Nosubnet    $routing_source            = lookup('profile::wmcs::cloudgw::routing_source_ip'),
    Array[Stdlib::IP::Address::V4]       $cloud_filter              = lookup('profile::wmcs::cloudgw::cloud_filter',               {default_value => []}),
    Array[Stdlib::IP::Address::V4]       $dmz_cidr                  = lookup('profile::wmcs::cloudgw::dmz_cidr',                   {default_value => []}),
    Array[Wmflib::IP::Address::CIDR]     $public_cidrs              = lookup('profile::wmcs::cloud_private_subnet::public_cidrs',  {default_value => []}),
    Stdlib::IP::Address::V4::Cidr        $cloud_private_supernet    = lookup('profile::wmcs::cloud_private_subnet::supernet_v4'),
) {
    include profile::logrotate

    ensure_packages('vlan')
    $nic_virt = "vlan${virt_vlan}"
    $nic_wan  = "vlan${wan_vlan}"

    $public_cidrs_v4 = $public_cidrs.filter |$net| { $net =~ Stdlib::IP::Address::V4::CIDR }

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
        base_interface => $facts['interface_primary'],
        vlan_id        => $virt_vlan,
        address        => $virt_addr,
        netmask        => $virt_netm,
    }

    interface::ip { "cloudgw_v6_${nic_virt}":
        interface => $nic_virt,
        address   => $virt_addr_v6,
        prefixlen => $virt_netm_v6,
    }

    interface::tagged { "cloudgw_${nic_wan}":
        base_interface => $facts['interface_primary'],
        vlan_id        => $wan_vlan,
        address        => $wan_addr,
        netmask        => $wan_netm,
    }

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

    interface::post_up_command { 'default_vrf_route_v6' :
        interface => $nic_wan,
        command   => "ip -6 route add table ${rt_table_name} default via ${wan_gw_v6} dev ${nic_wan}",
    }

    # route internal VM networks to neutron
    ($virt_subnets + $virt_internal_subnets).each |$net| {
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
    $virt_subnets_v6.each |$net| {
        interface::post_up_command { "route_${nic_virt}_virt_subnet_${net}" :
            interface => $nic_virt,
            command   => "ip -6 route add ${net} table ${rt_table_name} nexthop via ${virt_peer_v6} dev ${nic_virt}",
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
        config => template('profile/wmcs/cloudgw/keepalived.conf.erb'),
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

    firewall::service { 'conntrackd_tcp_3780':
        proto  => tcp,
        srange => [$conntrackd_remote_address],
        port   => 3780,
    }

    class { 'natlog':
        logrotate_frequency => $profile::logrotate::hourly.bool2str('hourly', 'daily'),
    }
}
