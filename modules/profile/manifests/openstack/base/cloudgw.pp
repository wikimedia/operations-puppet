class profile::openstack::base::cloudgw (
    Integer             $virt_vlan    = lookup('profile::openstack::base::cloudgw::virt_vlan',    {default_value => 2107}),
    Stdlib::IP::Address $virt_peer    = lookup('profile::openstack::base::cloudgw::virt_peer',    {default_value => '127.0.0.5'}),
    Stdlib::IP::Address::V4::CIDR $virt_floating= lookup('profile::openstack::base::cloudgw::virt_floating',{default_value => '127.0.0.5/24'}),
    Optional[Stdlib::IP::Address::V4::CIDR] $virt_floating_additional= lookup('profile::openstack::base::cloudgw::virt_floating_additional', {default_value => undef}),
    Stdlib::IP::Address $virt_cidr    = lookup('profile::openstack::base::cloudgw::virt_cidr',    {default_value => '127.0.0.6/24'}),
    Integer             $wan_vlan     = lookup('profile::openstack::base::cloudgw::wan_vlan',     {default_value => 2120}),
    Stdlib::IP::Address $wan_addr     = lookup('profile::openstack::base::cloudgw::wan_addr',     {default_value => '127.0.0.4'}),
    Integer             $wan_netm     = lookup('profile::openstack::base::cloudgw::wan_netm',     {default_value => 8}),
    Stdlib::IP::Address $wan_gw       = lookup('profile::openstack::base::cloudgw::wan_gw',       {default_value => '127.0.0.4'}),
    String              $nic_dataplane= lookup('profile::openstack::base::cloudgw::nic_dataplane',{default_value => 'eno2'}),
    String              $vrrp_passwd  = lookup('profile::openstack::base::cloudgw::vrrp_passwd',  {default_value => 'dummy'}),
    Array[String]       $vrrp_vips    = lookup('profile::openstack::base::cloudgw::vrrp_vips',    {default_value => ['127.0.0.1 dev eno2']}),
    Stdlib::IP::Address $vrrp_peer    = lookup('profile::openstack::base::cloudgw::vrrp_peer',    {default_value => '127.0.0.1'}),
    Hash                $conntrackd   = lookup('profile::openstack::base::cloudgw::conntrackd',   {default_value => {}}),
    Stdlib::IP::Address           $routing_source = lookup('profile::openstack::base::cloudgw::routing_source_ip',{default_value => '127.0.0.7'}),
    Stdlib::IP::Address::V4::CIDR $virt_subnet    = lookup('profile::openstack::base::cloudgw::virt_subnet_cidr', {default_value => '127.0.0.8/32'}),
    Array[Stdlib::IP::Address::V4::Nosubnet] $dmz_cidr = lookup('profile::openstack::base::cloudgw::dmz_cidr',    {default_value => ['0.0.0.0']}),
) {
    class { '::nftables':
        ensure_package => 'present',
        ensure_service => 'present',
    }

    $nic_virt = "${nic_dataplane}.${virt_vlan}"
    $nic_wan  = "${nic_dataplane}.${wan_vlan}"

    nftables::file { 'cloudgw':
        ensure  => present,
        order   => 1,
        content => template('profile/openstack/base/cloudgw/cloudgw.nft.erb'),
    }

    # network config, VRF, vlan trunk, routing, etc
    file { '/etc/network/interfaces.d/cloudgw':
        ensure  => present,
        content => template('profile/openstack/base/cloudgw/interfaces.erb'),
    }

    $rt_table = 10
    file { '/etc/iproute2/rt_tables.d/cloudgw.conf':
        ensure  => present,
        content => "${rt_table} cloudgw\n",
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


    if $virt_floating_additional != undef {
        $keepalived_routes = [
            # route floating IPs to neutron
            "${virt_floating} table ${rt_table} nexthop via ${virt_peer} dev ${nic_dataplane}.${virt_vlan} onlink",
            "${virt_floating_additional} table ${rt_table} nexthop via ${virt_peer} dev ${nic_dataplane}.${virt_vlan} onlink",
            # route internal VM network to neutron
            "${virt_cidr} table ${rt_table} nexthop via ${virt_peer} dev ${nic_dataplane}.${virt_vlan} onlink",
        ]
    } else {
        $keepalived_routes = [
            # route floating IPs to neutron
            "${virt_floating} table ${rt_table} nexthop via ${virt_peer} dev ${nic_dataplane}.${virt_vlan} onlink",
            # route internal VM network to neutron
            "${virt_cidr} table ${rt_table} nexthop via ${virt_peer} dev ${nic_dataplane}.${virt_vlan} onlink",
        ]
    }

    class { 'keepalived':
        peers     => ['example.com'], # overriden by config template
        auth_pass => 'ignored',       # overriden by config template
        vips      => ['127.0.0.1'],   # overriden by config template
        config    => template('profile/openstack/base/cloudgw/keepalived.conf.erb'),
    }

    nftables::file { 'keepalived_vrrp':
        content => "add rule inet basefirewall input ip saddr ${vrrp_peer} ip protocol vrrp accept\n",
    }

    # this expects a data structure like this:
    # profile::openstack::base::cloudgw::conntrackd_conf:
    #   node1:
    #     nic: eno0
    #     local_addr: node1.dc.wmnet
    #     remote_addr: node2.dc.wmnet
    #     filter_ipv4:
    #      - x.x.x.x
    #      - y.y.y.y
    #   node2:
    #     nic: eno0
    #     local_addr: node2.dc.wmnet
    #     remote_addr: node1.dc.wmnet
    #     filter_ipv4:
    #      - x.x.x.x
    #      - y.y.y.y

    $conntrackd_nic            = $conntrackd[$::hostname]['nic']
    $conntrackd_local_address  = ipresolve($conntrackd[$::hostname]['local_addr'], 4)
    $conntrackd_remote_address = ipresolve($conntrackd[$::hostname]['remote_addr'], 4)
    $conntrackd_filter_ipv4    = $conntrackd[$::hostname]['filter_ipv4']

    class { 'conntrackd':
        conntrackd_cfg => template('profile/openstack/base/cloudgw/conntrackd.conf.erb'),
        systemd_cfg    => file('profile/openstack/base/cloudgw/conntrackd.service'),
    }

    nftables::file { 'conntrackd_tcp_3780':
        order   => 1,
        content => "add rule inet basefirewall input ip saddr ${conntrackd_remote_address} tcp dport 3780 ct state new accept\n",
    }
}
