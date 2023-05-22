class profile::wmcs::cloudgw (
    Stdlib::IP::Address::V4::CIDR                  $virt_subnet               = lookup('profile::wmcs::cloudgw::virt_subnet_cidr',         {default_value => '172.16.128.0/24'}),
    Integer                                        $virt_vlan                 = lookup('profile::wmcs::cloudgw::virt_vlan',                {default_value => 2107}),
    Stdlib::IP::Address                            $virt_peer                 = lookup('profile::wmcs::cloudgw::virt_peer',                {default_value => '127.0.0.5'}),
    Stdlib::IP::Address::V4::CIDR                  $virt_floating             = lookup('profile::wmcs::cloudgw::virt_floating',            {default_value => '127.0.0.5/24'}),
    Optional[Stdlib::IP::Address::V4::CIDR]        $virt_floating_additional  = lookup('profile::wmcs::cloudgw::virt_floating_additional', {default_value => undef}),
    Integer                                        $wan_vlan                  = lookup('profile::wmcs::cloudgw::wan_vlan',                 {default_value => 2120}),
    Stdlib::IP::Address                            $wan_addr                  = lookup('profile::wmcs::cloudgw::wan_addr',                 {default_value => '127.0.0.4'}),
    Integer                                        $wan_netm                  = lookup('profile::wmcs::cloudgw::wan_netm',                 {default_value => 8}),
    Stdlib::IP::Address                            $wan_gw                    = lookup('profile::wmcs::cloudgw::wan_gw',                   {default_value => '127.0.0.1'}),
    Array[String]                                  $vrrp_vips                 = lookup('profile::wmcs::cloudgw::vrrp_vips',                {default_value => ['127.0.0.1 dev eno2']}),
    Stdlib::IP::Address                            $vrrp_peer                 = lookup('profile::wmcs::cloudgw::vrrp_peer',                {default_value => '127.0.0.1'}),
    String[1]                                      $vrrp_passwd               = lookup('profile::wmcs::cloudgw::vrrp_passwd',              {default_value => 'dummy'}),
    Hash                                           $conntrackd                = lookup('profile::wmcs::cloudgw::conntrackd',               {default_value => {}}),
    Stdlib::IP::Address                            $routing_source            = lookup('profile::wmcs::cloudgw::routing_source_ip',        {default_value => '127.0.0.7'}),
    Stdlib::IP::Address::V4::CIDR                  $transport_cidr            = lookup('profile::wmcs::cloudgw::transport_cidr'),
    Stdlib::IP::Address::V4::Nosubnet              $transport_vip             = lookup('profile::wmcs::cloudgw::transport_vip'),
    Optional[Array[Stdlib::IP::Address::V4]]       $cloud_filter              = lookup('profile::wmcs::cloudgw::cloud_filter',             {default_value => []}),
    Array[Stdlib::IP::Address::V4]                 $dmz_cidr                  = lookup('profile::wmcs::cloudgw::dmz_cidr',                 {default_value => ['0.0.0.0']}),
    Optional[Array[Stdlib::IP::Address::V4::Cidr]] $public_cidrs              = lookup('profile::wmcs::cloud_private_subnet::public_cidrs',{default_value => []}),
) {

    ensure_packages('vlan')
    $nic_virt = "vlan${virt_vlan}"
    $nic_wan  = "vlan${wan_vlan}"

    $actual_dmz_cidr = $dmz_cidr + $public_cidrs

    nftables::file { 'cloudgw':
        ensure  => present,
        order   => 110,
        content => template('profile/wmcs/cloudgw/cloudgw.nft.erb'),
    }

    $rt_table_number = 10
    $rt_table_name = 'cloudgw'
    file { "/etc/iproute2/rt_tables.d/${rt_table_name}.conf":
        ensure  => present,
        content => "${rt_table_number} ${rt_table_name}\n",
    }

    $cloud_realm_routes = [[
        # route floating IPs to neutron. The 'onlink' is required for the route to don't be rejected as
        # the /30 subnet doesn't allow per-cloudgw-node address
        "${virt_floating} table ${rt_table_name} nexthop via ${virt_peer} dev ${nic_virt} onlink",
        # route internal VM network to neutron
        "${virt_subnet} table ${rt_table_name} nexthop via ${virt_peer} dev ${nic_virt} onlink",
        # select source address for the transport cloudgw <-> neutron subnet
        "${transport_cidr} table ${rt_table_name} dev ${nic_virt} scope link src ${transport_vip}",
    ] + [$virt_floating_additional.empty.bool2str('',
        # route additional floatings IPs to neutron
        "${virt_floating_additional} table ${rt_table_name} nexthop via ${virt_peer} dev ${nic_virt} onlink"
    )]].flatten.filter |$x| { $x !~ /^\s*$/ }

    # network config, VRF, vlan trunk, routing, etc
    file { '/etc/network/interfaces.d/cloudgw':
        ensure  => present,
        content => template('profile/wmcs/cloudgw/interfaces.erb'),
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
            # are flowing through cloudgw servers
            # default buckets is 65536. Let's use x8; 65536 * 8 = 524288
            # default max is buckets x4; 524288 * 4 = 2097152
            'net.netfilter.nf_conntrack_buckets'        => 524288,
            'net.netfilter.nf_conntrack_max'            => 2097152,
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
