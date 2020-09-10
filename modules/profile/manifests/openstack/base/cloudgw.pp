class profile::openstack::base::cloudgw (
    Array[String]       $all_phy_nics = lookup('profile::openstack::base::cloudgw::all_phy_nics', {default_value => ['eno1']}),
    Integer             $host_vlan    = lookup('profile::openstack::base::cloudgw::host_vlan',    {default_value => 2118}),
    Stdlib::IP::Address $host_addr    = lookup('profile::openstack::base::cloudgw::host_addr',    {default_value => '127.0.0.2'}),
    Integer             $host_netm    = lookup('profile::openstack::base::cloudgw::host_netm',    {default_value => 8}),
    Integer             $virt_vlan    = lookup('profile::openstack::base::cloudgw::virt_vlan',    {default_value => 2120}),
    Stdlib::IP::Address $virt_addr    = lookup('profile::openstack::base::cloudgw::virt_addr',    {default_value => '127.0.0.3'}),
    Integer             $virt_netm    = lookup('profile::openstack::base::cloudgw::virt_netm',    {default_value => 8}),
    Integer             $wan_vlan     = lookup('profile::openstack::base::cloudgw::wan_vlan',     {default_value => 2107}),
    Stdlib::IP::Address $wan_addr     = lookup('profile::openstack::base::cloudgw::wan_addr',     {default_value => '127.0.0.4'}),
    Integer             $wan_netm     = lookup('profile::openstack::base::cloudgw::wan_netm',     {default_value => 8}),
) {
    # need nft >= 0.9.6 and kernel >= 5.6 to use some of the concatenated rules
    apt::pin { 'nft-from-buster-bpo':
        package  => 'nftables libnftables1 libnftnl11 linux-image-amd64',
        pin      => 'release n=buster-backports',
        priority => 1001,
        before   => Class['::nftables'],
        notify   => Exec['apt-get-update'],
    }

    exec { 'apt-get-update':
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
    }

    class { '::nftables':
        ensure_service => 'present',
    }

    # bonding + trunking
    $bond_device = 'bond0'
    interface::aggregate { $bond_device:
        members => $all_phy_nics,
    }

    interface::tagged { "vlan${host_vlan}":
        base_interface     => $bond_device,
        vlan_id            => $host_vlan,
        address            => $host_addr,
        netmask            => $host_netm,
        legacy_vlan_naming => false,
    }

    interface::tagged { "vlan${virt_vlan}":
        base_interface     => $bond_device,
        vlan_id            => $virt_vlan,
        address            => $virt_addr,
        netmask            => $virt_netm,
        legacy_vlan_naming => false,
    }

    interface::tagged { "vlan${wan_vlan}":
        base_interface     => $bond_device,
        vlan_id            => $wan_vlan,
        address            => $wan_addr,
        netmask            => $wan_netm,
        legacy_vlan_naming => false,
    }

    # placeholder for HA stuff: keepalived and conntrackd
}
